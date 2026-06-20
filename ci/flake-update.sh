#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

base_dir="$(mktemp -d)"
trap 'rm -rf "$base_dir"' EXIT

git archive HEAD | tar -x -C "$base_dir"

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

  if [ -s "$host_report" ]; then
    {
      echo "## $host"
      echo
      echo '```text'
      cat "$host_report"
      echo '```'
      echo
    } >> "$report_file"
  fi
done

if ! find "$host_report_dir" -type f -size +0c | grep -q .; then
  git checkout -- flake.lock
  echo "changed=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  echo "flake.lock changed but host package closure report was empty"
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
