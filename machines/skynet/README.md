# Skynet

Flake output: `skynet`. [`inference.nix`](inference.nix) serves the pinned
Qwen3.5-122B-A10B-FP8 revision with TP2, 32768-token context and concurrency 4.
The container remains offline (`network=none`) with its existing bearer auth,
Unix socket and restricted Nginx ingress.

## vLLM 0.34.0 upgrade

The [release](https://github.com/vllm-project/vllm/releases/tag/v0.34.0) replaces
0.33.0. On 2026-11-17, public Docker Hub metadata requests verified the pinned
index digest and its linux/amd64 manifest
`sha256:cf5b2fdd087eb4f6d261736967cc5cde974bd22ff4df50365f8fa419b6b4c484`;
both registry digests matched locally calculated SHA-256 hashes. No layers were
downloaded and no runtime test was performed.

- Model Runner V1 is removed; no `VLLM_USE_V2_MODEL_RUNNER=0` is configured here.
- `--block-size=16` retains the previous base-size intent instead of the new
  default 64. The tagged [FlashAttention backend](https://github.com/vllm-project/vllm/blob/v0.34.0/vllm/v1/attention/backends/flash_attn.py)
  supports multiples of 16 for this Hopper/non-FP8-KV configuration (FP8 model
  weights do not imply FP8 KV cache). Qwen3.5 is hybrid: upstream
  [platform alignment](https://github.com/vllm-project/vllm/blob/v0.34.0/vllm/platforms/interface.py)
  may increase even an explicit size to fit its recurrent-state pages. Check
  the effective size/backend at startup; this is not a promise of 16-token pages.
- Keep `--gpu-memory-utilization=0.85`. Contrary to the release-note shorthand,
  the tagged [cache configuration](https://github.com/vllm-project/vllm/blob/v0.34.0/vllm/config/cache.py)
  and [resolver](https://github.com/vllm-project/vllm/blob/v0.34.0/vllm/config/vllm.py)
  do **not** disable extensible KV cache for an explicit utilization value.
  It remains enabled by default on supported CUDA/VMM systems, sizing after
  warmup within the 0.85 budget, with fallback if driver VMM is unsupported.
  Cache sizing therefore is not guaranteed identical to 0.33.0.

Before deployment, obtain a successful build of the intended `skynet` revision,
check auto-upgrade service/timers, retain the previous image/generation for
rollback, and verify the pinned model/tokenizer files are complete in
`/var/lib/skynet-inference` for offline startup. Deployment and runtime testing
require separate authorization; a host build does not test the container.

On the reported two H100 NVL GPUs (95830 MiB each, driver 595.112.07), verify
CUDA 13.0 image startup, TP2/NCCL on loopback, model loading and cache allocation
without OOM. Then test authenticated model listing, ordinary and streamed chat,
Qwen reasoning/tool calls, a near-32k request and four concurrent requests;
compare memory use, latency and throughput with 0.33.0. Confirm missing/invalid
keys and disallowed ingress still fail. None of these runtime checks has run.
