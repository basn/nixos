# Only the fixed public repository and its freshly fetched main are accepted.
[[ $# == 1 && "$1" =~ ^[0-9a-f]{40}$ ]] || exit 64
umask 077
export HOME=/var/lib/hermes-audit
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_TERMINAL_PROMPT=0
export NIX_CONFIG='experimental-features = nix-command flakes'
export NIX_PATH=''
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
mkdir -p "$HOME"
exec 9>"$HOME/validation.lock"
flock -n 9 || { echo 'ENVIRONMENT_ERROR: another audit is running' >&2; exit 75; }
# Bound the evaluator without granting trusted-user or root privileges. Full
# fleet evaluation has exceeded 12 GiB; keep headroom below this 32 GiB host.
ulimit -v 25165824
work=$(mktemp -d "$HOME/check.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT
export XDG_CACHE_HOME="$work/cache"
if ! git clone --quiet --depth=1 --single-branch --branch main \
  https://github.com/basn/nixos.git "$work/nixos"; then
  echo 'ENVIRONMENT_ERROR: fresh GitHub clone failed' >&2
  exit 69
fi
cd "$work/nixos"
actual=$(git rev-parse HEAD)
printf 'CHECKOUT_COMMIT=%s\n' "$actual"
if [[ "$actual" != "$1" ]]; then
  echo 'REVISION_CHANGED: main advanced; fetch again before validating' >&2
  exit 75
fi
before=$(sha256sum flake.lock)
# The pinned Hermes module refers to its input package lazily. On this
# persistent daemon, a broad check has observed that source path disappearing
# before the Hermes configuration forces it. Materialize that toplevel first;
# the full check below remains the authoritative result.
set +e
nix eval --no-write-lock-file --raw \
  .#nixosConfigurations.hermes.config.system.build.toplevel.drvPath \
  >/dev/null
materialize_status=$?
set -e
printf 'HERMES_MATERIALIZE_EXIT=%s\n' "$materialize_status"
printf 'VALIDATION_COMMAND=nix flake check --no-build --no-write-lock-file\n'
set +e
nix flake check --no-build --no-write-lock-file
status=$?
set -e
printf 'NIX_FLAKE_CHECK_EXIT=%s\n' "$status"
after=$(sha256sum flake.lock)
if [[ "$before" != "$after" ]]; then
  echo 'LOCKFILE_CHANGED: unexpected validation side effect' >&2
  [[ "$status" != 0 ]] || status=74
fi
# Preserve the actual Nix failure. Its stderr distinguishes repository errors
# from daemon, fetch, permission, resource, or network failures.
exit "$status"
