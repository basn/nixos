# Run from Hermes's Docker terminal backend. No deployment or image pulls.
[[ $# == 0 ]] || { echo 'Usage: basn-audit' >&2; exit 64; }
umask 077
for registry in github.com ghcr.io registry-1.docker.io auth.docker.io docker.dragonflydb.io; do
  printf 'DNS_CHECK=%s\n' "$registry"
  getent ahostsv4 "$registry" || { echo 'ENVIRONMENT_ERROR: DNS failed' >&2; exit 69; }
done
curl --fail --silent --show-error --location --connect-timeout 10 --max-time 30 \
  --output /dev/null https://github.com/basn/nixos
work=$(mktemp -d /workspace/nixos-audit.XXXXXXXX)
git clone --quiet --depth=1 --single-branch --branch main \
  https://github.com/basn/nixos.git "$work/repo"
cd "$work/repo"
revision=$(git rev-parse HEAD)
printf 'CHECKOUT_PATH=%s\nCHECKOUT_COMMIT=%s\n' "$work/repo" "$revision"
before=$(sha256sum flake.lock)

# This is a literal image in the fresh repository, not a hard-coded old tag.
# Skopeo rejects tag+digest references; use the digest when both are specified.
image=$(python3 - <<'PY'
import pathlib,re
text=pathlib.Path('machines/services/services/authentik.nix').read_text()
m=re.search(r'image\s*=\s*"(docker\.io/library/postgres:[^"\s]+)"',text)
if not m:
    raise SystemExit('REPOSITORY_ERROR: configured PostgreSQL image was not found')
image=m.group(1)
if '@' in image:
    name,digest=image.split('@',1)
    image=name.rsplit(':',1)[0]+'@'+digest
print(image)
PY
)
printf 'OCI_REFERENCE=%s\n' "$image"
status=0
set +e
skopeo inspect --override-os linux --override-arch amd64 \
  --format 'REGISTRY_DIGEST={{.Digest}}' "docker://$image"
rc=$?
printf 'SKOPEO_EXIT=%s\n' "$rc"
[[ "$rc" == 0 ]] || status=$rc
for target in audit-services audit-hermes; do
  printf 'HEALTH_TARGET=%s\n' "$target"
  ssh -F /etc/ssh/audit_config "$target" health
  rc=$?
  printf 'HEALTH_EXIT=%s\n' "$rc"
  [[ "$rc" == 0 ]] || status=$rc
done
ssh -F /etc/ssh/audit_config audit-nixos-sov "validate $revision"
nix_status=$?
printf 'VALIDATION_SSH_EXIT=%s\n' "$nix_status"
[[ "$nix_status" == 0 ]] || status=$nix_status
set -e
[[ "$before" == "$(sha256sum flake.lock)" ]] || { echo 'LOCKFILE_CHANGED' >&2; exit 74; }
printf 'AUDIT_EXIT=%s\n' "$status"
exit "$status"
