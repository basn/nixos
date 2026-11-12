# Skynet

Fresh x86_64 VMware server with the normal shared server baseline, using the
existing locked `nixpkgs-unstable-small` input and one vLLM inference service. Its initial
`system.stateVersion` is `26.11`; keep it unchanged after installation.

## Provisioning assumptions

Disk preparation is not required before a Git push. Provision storage separately
before installing; this configuration does not partition disks or create pools,
datasets, or filesystems:

- The confirmed fresh VM disk is `/dev/sda` (1 TB), intended for a 1 GiB EFI
  partition and ZFS on the remainder. Actual disk preparation is not verified.
- Boot the VM and installer in EFI mode. systemd-boot uses the EFI system
  partition at `/boot`; installation registers its EFI boot entry in firmware.
- Create the `osdisk` ZFS pool with datasets `osdisk/root`, `osdisk/nix`,
  `osdisk/var`, and `osdisk/home`, each using `mountpoint=legacy` for the declared
  NixOS filesystem mounts. Before installation, mount them at `/mnt`, `/mnt/nix`,
  `/mnt/var`, and `/mnt/home`, respectively.
- Create a FAT32 EFI system partition (1 GiB recommended) with **filesystem label
  `SKYNET-EFI`** (not merely a GPT partition label), mounted at `/mnt/boot` before
  installation. The installed system mounts it at `/boot`.
- ZFS discovers devices through `/dev/disk/by-path`; root pool force-import is
  disabled. The host has its own ZFS host ID, `5018a94f`.
- There is no swap, backup pool, or inherited source-host disk UUID.
- After installation and before first boot, cleanly unmount the target
  filesystems and export only `osdisk`, not any installer pools. With
  `forceImportRoot = false` and a target host ID different from the installer's,
  a clean export is needed for the target to import the pool normally.

The confirmed NIC is `ens33`. It uses `10.136.48.5/24`, gateway `10.136.48.1`, and DNS
`8.8.8.8`. DHCP and IPv6 are disabled. The firewall allows SSH and the normal
NetBird client traffic, plus monitoring ports 9100 and 9633 only from collector
`100.86.89.177` over `wt0`. Inference HTTPS allows TCP 443 only on `ens33`;
the deployed inference configuration publishes no container TCP ports and uses
no container bridge. Podman's host-wide defaults remain unchanged, including
TCP/UDP 53 firewall rules on `podman+` bridges. Existing host addressing and
storage stay unchanged.

## Administration and builds

NVIDIA runs headless with the open kernel module and proprietary userspace;
X, a display manager, and the NVIDIA settings GUI are disabled. Verified hardware
is two passed-through H100 NVL GPUs (93.6 GiB VRAM each), 503 GiB host RAM and 32
logical CPUs, with about 979 GiB available on shared ZFS. The inspected driver was
595.112.07 with kernel 6.18.62. Secure Boot is not configured here.

The normal user `basn` inherits `common/users.nix`, including its public SSH
keys, Fish shell, user packages, and `wheel` membership. Those existing key
holders receive passwordless sudo. SSH
password and keyboard-interactive authentication and root SSH login are
disabled. No root password is provisioned; retain console access during setup.

The shared baseline includes the normal tools, NVF, locale/time settings,
trusted Attic cache, cleanup, SSH, NetBird, and node/smartctl exporters. VMware
guest support and automatic upgrades are enabled. The shared ZFS role keeps
scrubbing enabled and configures ZED mail through msmtp with a SOPS-managed
password. Skynet's recipient is enrolled for this ZFS secret; decryption and
ZED activation were verified on 2026-11-12, but mail delivery was not tested.
Upgrade webhook notifications remain deferred. The SOPS
CLI remains a baseline tool. The smartd role remains disabled.
Other than inference and its nginx HTTPS proxy, no application services, runners, audit agents,
Kuma, syncoid, or backup jobs are added. The existing boot, ZFS, network,
administration and shared baseline settings are unchanged.

## Inference

`inference.nix` runs `Qwen/Qwen3.5-122B-A10B-FP8` using rootful Podman and NVIDIA
CDI, without privileged mode, host networking or host IPC. Pins:

- Official image: `docker.io/vllm/vllm-openai:v0.33.0@sha256:d825baf9ce4b1b6bfc5ecc7b79880c7e6748c65a72d697ce3d47607aafa84c6e`
  (multiarch manifest; amd64 child `sha256:91ee972ab751fb7180bc71c175865e36b091686600dca783d52b2511399810b3`).
- Model and tokenizer revision: `a099dee70ccfcd8d5dda56aaa0b60cb8ecadabc9`.
- The image supplies CUDA 13.0.2 and the `vllm serve` entrypoint; the model is its
  first positional argument. The locked native vLLM package is broken with CUDA,
  so no native vLLM/CUDA build or broken-package override is used.

The checkpoint supplies FP8 quantization; loading is safetensors-only without
remote code trust. Tensor parallelism uses both GPUs with the multiprocessing
executor, 32,768-token context, one concurrent sequence, 85% GPU memory utilization,
and vLLM's supported `qwen3` reasoning parser. Shared memory is private and 16 GiB.
Automatic tool choice is enabled with the `qwen3_coder` tool-call parser recommended
by Qwen for Qwen3.5, allowing clients such as OpenCode to send `tool_choice: auto`.
After deployment on 2026-11-12, non-streaming and streaming SSE requests with
automatic tool choice both returned `record_test_value` with exactly `{"value":7}`,
a nonempty call ID and `finish_reason: tool_calls`. The synthetic tool was not executed.
The deployed offline configuration passed authenticated model-list and short chat
tests on both GPUs on 2026-11-12, using about 81,500 MiB per GPU. The VM reports a
`SYS` interconnect, not NVLink; startup logs include unsupported FlashInfer
all-reduce fusion/CUDA device warnings, followed by successful inference without
NCCL/P2P overrides. A controlled restart took about six minutes to become ready,
including compilation and shared-memory wait warnings. Long-context and load
behavior remain unverified.

The root-owned cache is `/var/lib/skynet-inference` (mode `0700`), mounted as
`/cache` with `HF_HOME=/cache`. Budget roughly 125 GB or more for weights, about
10 GB compressed for the image, plus unpacked layers, caches and temporary
download space on the shared ZFS pool. Podman may pull the image on the host
after activation, **not during `nix build`**; this host-side network access is
outside the isolated container. Existing model weights are already cached;
the deployed configuration requires all model/tokenizer artifacts in that cache
and fails closed if any are missing. A new model or revision requires a separately
authorized network-enabled cache prefetch, never temporarily enabling networking
on the inference container. The inherited startup timeout is unlimited for the
image pull; failures restart after 30 seconds. Systemd becoming active
only means the container started, not that the model is ready.

### Network isolation, HTTPS and API authentication

The deployed container uses `--network=none`: no outbound internet, external DNS,
or host network access. Its own loopback remains available for the two GPU
workers, with NCCL/Gloo bootstrap restricted to `lo`. Offline/telemetry environment
flags supplement this isolation; the network namespace is the security boundary.
nginx reaches vLLM only through `/run/skynet-inference/api/vllm.sock`, not TCP 8000.
Only the `api` child is bind-mounted into the container, never Podman's runtime
files or daemon socket. The root-owned setgid socket directory lets nginx traverse
but not write it; the socket grants nginx group read/write. Systemd removes the
runtime directory on stop/restart, so a stale socket does not survive a restart.
The persistent root-only model cache is unchanged.

Client-side OpenCode tools run independently and are not blocked by this container
isolation. External image/media URLs cannot be fetched by the model; inline
uploads may still be accepted by the model/API. NetBird SSH administration is
unaffected.

Public base URL: **`https://81.91.1.125/v1`**. This is public NAT, not NetBird.
A separately authorized router change must forward external TCP 443 to
`10.136.48.5:443`. nginx listens only on that LAN address, with no port 80,
ACME, or IP allowlist. Only `GET /v1/models` and `POST /v1/chat/completions`
are proxied to literal upstream paths; other routes return 404 and unsupported
methods return 405. Chat supports streaming SSE with a 600-second proxy timeout.
Health, metrics, docs and administrative routes are not exposed publicly.
Send credentials only in the `Authorization: Bearer` header, never in query
strings. Standard nginx logging remains enabled and does not log this header.

vLLM listens only on the Unix socket and requires a bearer API key, including local
model/chat requests. A startup check rejects missing or malformed keys before
the container starts. The API key and TLS private key are encrypted in
`secrets/inference.yaml`, readable only by basn's and Skynet's age recipients.
At activation, SOPS supplies a root-only API secret and environment file, and a
root:nginx `0440` TLS key. Neither plaintext credential enters the Nix store.
Root and Podman administrators can inspect container environments: avoid broad
environment dumps or `podman inspect` diagnostics.

The public certificate is [`inference.crt`](inference.crt), valid until
**2027-11-12 09:15:21 UTC**, with SHA-256 fingerprint:

```text
8D:DD:B0:C6:20:99:0C:4E:BA:57:75:63:38:FB:4F:03:46:34:97:72:2E:25:C6:27:3A:30:97:18:51:D8:98:F6
```

Obtain this public file and fingerprint through a trusted checkout/channel,
not an unauthenticated download from the endpoint. Verify before trusting it:

```sh
openssl x509 -in machines/skynet/inference.crt -noout -sha256 -fingerprint -dates
openssl verify -check_ss_sig -CAfile machines/skynet/inference.crt \
  -verify_ip 81.91.1.125 machines/skynet/inference.crt
```

After separate authorization, extract the API key on the client into a private
file, never into chat or terminal output (run from the trusted checkout with
your existing SOPS identity):

```sh
install -d -m 700 ~/.secrets
(umask 077; sops --decrypt --extract '["VLLM_API_KEY"]' \
  machines/skynet/secrets/inference.yaml > ~/.secrets/skynet-api-key)
chmod 600 ~/.secrets/skynet-api-key
```

OpenCode V2 provider settings support `apiKey: "{file:~/.secrets/skynet-api-key}"`
or `apiKey: "{env:VLLM_API_KEY}"`. Configure the provider's base URL as above.
The Node process making HTTPS requests must trust the public certificate through
`NODE_EXTRA_CA_CERTS=/absolute/path/to/inference.crt` at process startup. For
OpenCode's managed background service, configuring only the terminal/client
environment is insufficient if the service is already running; configure its
actual launch environment separately. No client/service configuration is changed
here. Never disable TLS verification or use `curl -k`.

Renew manually **before expiry**: generate a new one-year IP-SAN certificate
and private key in a private ephemeral directory, encrypt the replacement private
key under `tls_private_key` with the same two recipients (preserve the API key),
replace the public PEM, verify the key match/IP/signature, and redistribute the
new trusted certificate/fingerprint to clients before switching. Clean up all
plaintext temporary material. There is no renewal service or private CA.
API key rotation requires updating the encrypted key and client file; SOPS
restarts the container when its rendered environment changes, and nginx when its
private key changes.

Deployed over verified NetBird SSH on **2026-11-12**, without rebooting:

```text
/nix/store/dzimd9419i6ki31jyrzkh21fk46wnymp-nixos-system-skynet-26.11.20261111.1880819
```

Acceptance passed before and after a controlled declarative-unit restart:
offline dual-GPU readiness; nginx/CDI/container/ZED/scrub timer active with no
failed units; secret modes and rendered API key equality; socket `root:nginx`
`0770`, accessible to nginx but denied to `nobody`; runtime-directory recreation
and old-socket removal. The container had only loopback, no IPv4/IPv6 default
route, no published ports, private IPC and no privileged mode. Bounded literal
IPv4/IPv6, LAN/gateway and external DNS probes failed; loopback communication
succeeded. Only LAN `10.136.48.5:443` listened for inference, with no TCP 80/8000.

HTTPS tests connected to the LAN address while verifying the trusted certificate
for `81.91.1.125`: missing/wrong tokens returned 401 for models/chat; valid tokens
returned 200 for models, short chat and both tool-call modes. Unexposed routes
returned 404, malformed above-root traversal 400, and unsupported methods 405.
SSE events arrived before completion (six events, about 0.17–0.35 seconds after
the post-restart request began). No synthetic tool was executed.

The unauthenticated public-IP TLS probe timed out from the deployment client.
Router NAT, external reachability and real client trust/authentication remain
unverified; no router settings were changed. Clients must trust the public PEM
and use their private API key file. The certificate still requires manual renewal.

## Setup blockers and enrollment

Skynet's existing public ED25519 host key was retrieved over verified NetBird
SSH and its age recipient added to `.sops.yaml`. Only `secrets/zfs.yaml` was
rewrapped, preserving its existing recipients. The configuration declares its
`password` key as root-only `/run/secrets/zfs`, using the persistent host key at
`/etc/ssh/ssh_host_ed25519_key`. No private host key was retrieved.

This enrollment and ZFS mail configuration were deployed on 2026-11-12.
Live secret decryption and active ZED/scrub timer were verified; no test mail or
heavy scrub was started, so delivery remains unverified.
Upgrade notifications remain disabled: `secrets/webhook.yaml` was not rewrapped
for Skynet and `/run/secrets/nixos-upgrade-webhook` is not declared. Enrolling that
secret and enabling its role require a separate change.

NetBird is enabled and this host is already enrolled with `https://netbird.basn.se`.
Fresh installations require manual enrollment before remote access over NetBird.
Exporter configuration and firewall rules alone do not enroll the host in
central monitoring; collector-side scrape registration remains to be done
separately after enrollment. No collector configuration is changed here.

The host automatically enters the flake-derived CI build matrix. Automatic
upgrades follow the public `git+https://github.com/basn/nixos` configuration
nightly, with the shared randomized delay and no automatic reboot. At deployment,
the upgrade service was inactive and its next trigger was **2026-11-13 02:42:14
CET**. The timer was not changed. Nothing has been pushed: the timer does not
use unpublished local commits and may replace this deployment with public GitHub
configuration. Publish separately before relying on upgrades to preserve it.

Build the tracked local checkout:

```sh
nix build .#nixosConfigurations.skynet.config.system.build.toplevel --no-link --no-write-lock-file
```

Building does not provision storage or activate the configuration on a VM.
