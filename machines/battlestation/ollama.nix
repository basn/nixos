{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    loadModels = [ "qwen3:8b" ];
    environmentVariables = {
      # Keep the server available locally, but release its model and VRAM
      # shortly after the last request so gaming has the whole GPU.
      OLLAMA_KEEP_ALIVE = "5m";
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_NUM_PARALLEL = "1";
      OLLAMA_CONTEXT_LENGTH = "8192";
      OLLAMA_NO_CLOUD = "1";
    };
  };
}
