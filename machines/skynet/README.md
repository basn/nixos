# Skynet

Flake output: `skynet`. [`inference.nix`](inference.nix) configures
`Qwen/Qwen3.8-Flash-Next-FP8` at checkpoint revision
`7fb48d708ca6cd8eeed8f4db0433be18af96984f`. Clients must request that exact
model ID; `Qwen/Qwen3.5-122B-A10B-FP8` is not an alias. Serving is text-only
(`--language-model-only`), with a 262,144-token context and four concurrent
sequences. Multimodal inputs are disabled.

The offline container keeps the existing bearer authentication, Unix socket,
and restricted Nginx TLS ingress. The profile tested on two H100 NVL GPUs
uses the pinned vLLM 0.34.0 image, Python frontend, TP2, pinned-host Engram
CPU offload, Triton MoE, FP8 KV and indexer cache, 0.88 GPU memory utilization,
and a 320 GiB container memory limit with no swap allowance. Prefix caching
and speculative decoding (MTP) are off.

## Deploy and roll back

Before switching, verify the pinned official checkpoint against upstream file
hashes, including all 131 safetensors shards, the index and tokenizer. Put the
verified checkpoint under
`/var/lib/skynet-qwen38-fp8/7fb48d708ca6cd8eeed8f4db0433be18af96984f/checkpoint/`
with its verification report (`verified.json`, containing the revision) beside
`checkpoint/`. The service mounts only `checkpoint/`, read-only at `/model`.
Keep the previous Qwen3.5 cache at `/var/lib/skynet-inference` and retain the
previous image and NixOS generation for rollback.

Build the exact intended Skynet configuration and review the generation diff
before switching. Check `nixos-upgrade.service` and its timer; Skynet takes its
source from GitHub `main`. Confirm an allowlisted client is available. Drain
before stopping the previous service, and arm an independent host rollback
before interrupting production. On failure, restore the retained generation and
original admission, then verify the previous model returns an authenticated
completion and rejects unauthenticated requests.

After switching, check local socket health and authenticated model listing,
plain and streamed completions, and structured tool calls through the normal
TLS ingress from an allowlisted client. Confirm missing/invalid keys receive
`401`, disallowed clients receive `403`, and no temporary gate or watchdog
remains. In the isolated 256K trial on 2026-11-20, one stream retrieved an
exact hidden value from a 260,983-token prompt without truncation. The trial
did not test multiple near-limit streams or the production TLS path.

## vLLM image provenance

On 2026-11-17, public Docker Hub metadata for the pinned
[vLLM 0.34.0 release](https://github.com/vllm-project/vllm/releases/tag/v0.34.0)
verified the pinned index digest and its `linux/amd64` manifest digest
`sha256:cf5b2fdd087eb4f6d261736967cc5cde974bd22ff4df50365f8fa419b6b4c484`.
