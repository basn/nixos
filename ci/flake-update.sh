#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

base_dir="$(mktemp -d)"
trap 'rm -rf "$base_dir"' EXIT

git archive HEAD | tar -x -C "$base_dir"

is_meaningful_change() {
  local host="$1"
  local report_file="$2"

  if [ ! -s "$report_file" ]; then
    return 1
  fi

  if rg -q '^No version or selection state changes\.$' "$report_file"; then
    return 1
  fi

  if rg -q '^nvd diff failed for ' "$report_file"; then
    return 1
  fi

  # nvd emits package changes as table rows, not store paths. Keep only real
  # package rows and ignore the host system generation itself.
  local ignored_system_package
  ignored_system_package="nixos-system-${host//\//-}"

  awk -v ignored_system_package="$ignored_system_package" '
    /^\[[^]]+\][[:space:]]+#[0-9]+[[:space:]]+/ {
      package = $3
      if (package != ignored_system_package && package != "nixos-system") {
        found = 1
      }
    }

    END {
      exit found ? 0 : 1
    }
  ' "$report_file"
}

mapfile -t hosts < <(
  nix eval --json "$base_dir#nixosConfigurations" --apply 'configs: builtins.attrNames configs' \
    | jq -r '.[] | select(test("Iso$") | not)'
)

if [ "${#hosts[@]}" -eq 0 ]; then
  echo "No NixOS hosts found" >&2
  exit 1
fi

mkdir -p .ci
base_paths_file=".ci/base-paths"
candidate_paths_file=".ci/candidate-paths"
host_report_dir=".ci/host-reports"
report_file=".ci/flake-update-report.md"
: > "$base_paths_file"
: > "$candidate_paths_file"
rm -rf "$host_report_dir"
mkdir -p "$host_report_dir"
useful_hosts=0

{
  echo "# Flake update package changes"
  echo
  echo "Nightly flake input update. The report below is generated from NixOS host system closure diffs."
  echo
} > "$report_file"

for host in "${hosts[@]}"; do
  echo "Building current closure for $host"
  nix build "$base_dir#nixosConfigurations.$host.config.system.build.toplevel" --no-link --print-out-paths \
    >> "$base_paths_file"
done

nix flake update

if git diff --quiet -- flake.lock; then
  echo "changed=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  echo "flake.lock did not change"
  exit 0
fi

for i in "${!hosts[@]}"; do
  host="${hosts[$i]}"
  host_report="$host_report_dir/$host.md"
  echo "Building candidate closure for $host"
  candidate_path="$(
    nix build ".#nixosConfigurations.$host.config.system.build.toplevel" --no-link --print-out-paths
  )"
  echo "$candidate_path" >> "$candidate_paths_file"

  base_path="$(sed -n "$((i + 1))p" "$base_paths_file")"

  echo "Comparing package closure for $host"
  if nvd diff "$base_path" "$candidate_path" | tee "$host_report"; then
    :
  else
    echo "nvd diff failed for $host" | tee -a "$host_report"
  fi

  if is_meaningful_change "$host" "$host_report"; then
    useful_hosts=$((useful_hosts + 1))
    {
      echo "## $host"
      echo
      echo '```text'
      cat "$host_report"
      echo '```'
      echo
    } >> "$report_file"
  else
    echo "No package-level changes for $host"
  fi
done

if [ "$useful_hosts" -eq 0 ]; then
  git checkout -- flake.lock
  echo "changed=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  echo "flake.lock changed but no host had package version or selection changes"
  exit 0
fi

if [ -n "${ATTIC_TOKEN:-}" ]; then
  attic login ci "$ATTIC_ENDPOINT" "$ATTIC_TOKEN"
  xargs -r attic push "$ATTIC_CACHE" < "$candidate_paths_file"
else
  echo "ATTIC_TOKEN is not set; skipping Attic push" >&2
fi

echo "changed=true" >> "${GITHUB_OUTPUT:-/dev/null}"
echo "report=$report_file" >> "${GITHUB_OUTPUT:-/dev/null}"
