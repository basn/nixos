#!/usr/bin/env bash
# Run from the checkout root; never activate configurations.
set -uo pipefail

usage() {
  cat <<'EOF'
Usage: bash scripts/validate-flake.sh [options]
  --host NAME     Evaluate a host's toplevel derivation (repeatable)
  --all-hosts     Discover and evaluate every nixosConfiguration, including ISOs
  --build-checks  Allow flake check to build declared checks
  --build-hosts   Build selected toplevels sequentially, without result links
  --json          Emit one JSON summary (requires python3)
  --help          Show this help
Default: nix flake check --no-build, with import-from-derivation disabled.
Build flags require explicit build authorization. Logs persist under .ci/.
EOF
}
hosts=()
all_hosts=false
build_hosts=false
build_checks=false
json=false
while (($#)); do
  case $1 in
    --help) usage; exit 0 ;;
    --host)
      if (($# < 2)) || [[ $2 == --* || -z $2 ]]; then
        echo '--host requires a name' >&2; exit 64
      fi
      hosts+=("$2"); shift ;;
    --all-hosts) all_hosts=true ;;
    --build-checks) build_checks=true ;;
    --build-hosts) build_hosts=true ;;
    --json) json=true ;;
    *) printf 'Unknown argument: %q\n' "$1" >&2; exit 64 ;;
  esac
  shift
done
if $build_hosts && ! $all_hosts && ((${#hosts[@]} == 0)); then
  echo '--build-hosts requires --host or --all-hosts' >&2; exit 64
fi
if $json && ! command -v python3 >/dev/null; then
  echo '--json requires python3' >&2; exit 1
fi

umask 077
mkdir -p .ci || exit 1
logs=$(mktemp -d "$PWD/.ci/validate-flake.XXXXXXXX") || exit 1
labels=('flake check')
types=(flake_check)
stage_hosts=('')
exit_codes=('')
states=(skipped)
details=('not started')
stage_logs=("$logs/0")
mkdir "${stage_logs[0]}" || exit 1
failed=0
child=''
active_index=''
# Bash job control gives each Nix command its own process group for cancellation.
set -m
# shellcheck disable=SC2329 # Called by the EXIT trap.
summary() {
  local status=$1 i
  local fields=()
  if $json; then
    for i in "${!labels[@]}"; do
      fields+=("${types[i]}" "${stage_hosts[i]}" "${states[i]}" "${exit_codes[i]}" "${stage_logs[i]}" "${details[i]}")
    done
    python3 - "$status" "${fields[@]}" <<'PY' || status=1
import json
import sys

stages = []
for i in range(2, len(sys.argv), 6):
    stage, host, status, code, log, detail = sys.argv[i:i + 6]
    stages.append(dict(stage=stage, host=host or None, status=status,
                       exit_code=int(code) if code else None,
                       log_path=log, detail=detail))
print(json.dumps(dict(exit_code=int(sys.argv[1]), stages=stages)))
PY
  else
    printf '\nValidation summary (logs: %s)\n' "$logs"
    for i in "${!labels[@]}"; do
      printf '%s: %q (%s); log: %s\n' "${states[i]}" "${labels[i]}" "${details[i]}" "${stage_logs[i]}"
    done
  fi
  trap - EXIT
  exit "$status"
}
# shellcheck disable=SC2329 # Called by the INT/TERM traps.
interrupt() {
  local status
  trap '' INT TERM
  if [[ -n $child ]]; then
    kill -TERM -- "-$child" 2>/dev/null || true
    kill -KILL -- "-$child" 2>/dev/null || true
    wait "$child" 2>/dev/null; status=$?
    states[active_index]=failed
    exit_codes[active_index]=$status
    details[active_index]='interrupted before completion'
  fi
  exit "$1"
}
trap 'summary "$?"' EXIT
trap 'interrupt 130' INT
trap 'interrupt 143' TERM

add_stage() {
  labels+=("$1"); states+=(skipped); details+=('not started')
  types+=("$2"); stage_hosts+=("${3-}"); exit_codes+=('')
  stage_logs+=("$logs/$((${#labels[@]} - 1))")
  mkdir "${stage_logs[-1]}" || exit 1
}
run_stage() {
  local index=$1 status
  shift
  details[index]='interrupted before completion'
  active_index=$index
  "$@" >"${stage_logs[index]}/stdout" 2>"${stage_logs[index]}/stderr" &
  child=$!
  wait "$child"; status=$?
  child=''
  active_index=''
  exit_codes[index]=$status
  if ((status == 0)); then
    states[index]=passed; details[index]='exit 0'
  else
    states[index]=failed; details[index]="exit $status"; failed=1
  fi
}

lock_flags=(--no-write-lock-file --no-update-lock-file)
eval_flags=("${lock_flags[@]}" --option allow-import-from-derivation false)
check_flags=("${eval_flags[@]}" --no-build)
if $build_checks; then check_flags=("${lock_flags[@]}"); fi

if $all_hosts || ((${#hosts[@]})); then add_stage 'host discovery' host_discovery; fi
# Plan explicit hosts now so an interruption still reports unfinished work.
selected=()
for host in "${hosts[@]}"; do
  duplicate=false
  for name in "${selected[@]}"; do [[ $name != "$host" ]] || duplicate=true; done
  if ! $duplicate; then
    selected+=("$host")
    add_stage "evaluate $host" host_evaluation "$host"
    if $build_hosts; then add_stage "build $host" host_build "$host"; fi
  fi
done
run_stage 0 nix flake check "${check_flags[@]}"
if ! $all_hosts && ((${#selected[@]} == 0)); then exit "$failed"; fi

run_stage 1 nix eval "${eval_flags[@]}" --raw .#nixosConfigurations \
  --apply 'configs: builtins.concatStringsSep "\n" (builtins.attrNames configs)'
if [[ ${states[1]} != passed ]]; then
  if $all_hosts; then add_stage 'all hosts (inventory unavailable)' host_selection; fi
  exit 1
fi
inventory=()
mapfile -t inventory <"${stage_logs[1]}/stdout"
if $all_hosts; then
  for host in "${inventory[@]}"; do
    duplicate=false
    for name in "${selected[@]}"; do [[ $name != "$host" ]] || duplicate=true; done
    if ! $duplicate; then
      selected+=("$host")
      add_stage "evaluate $host" host_evaluation "$host"
      if $build_hosts; then add_stage "build $host" host_build "$host"; fi
    fi
  done
fi
index=2
for host in "${selected[@]}"; do
  known=false
  for name in "${inventory[@]}"; do [[ $name != "$host" ]] || known=true; done
  # Restrict the CLI boundary rather than interpreting arbitrary Nix attribute syntax.
  if ! $known || [[ ! $host =~ ^[a-zA-Z0-9_][a-zA-Z0-9_-]*$ ]]; then
    states[index]=failed; details[index]='unknown or unsupported host name'; failed=1
    exit_codes[index]=64
    printf '%q: unknown or unsupported host name\n' "$host" >"${stage_logs[index]}/stderr"
  else
    target=".#nixosConfigurations.\"$host\".config.system.build.toplevel"
    run_stage "$index" nix eval "${eval_flags[@]}" --raw "$target.drvPath"
  fi
  if $build_hosts; then
    if [[ ${states[index]} == passed ]]; then
      run_stage "$((index + 1))" nix build "${lock_flags[@]}" --no-link "$target"
    else
      details[index+1]='host evaluation failed'
    fi
    ((index+=1))
  fi
  ((index+=1))
done
exit "$failed"
