{ pkgs, ... }:
{
  hjem.users.basn.files = {
    ".config/fish/conf.d/codex-nix.fish".source = pkgs.writeText "codex-nix.fish" ''
      # Run Codex with the runtime tools required by its sandbox and MCP servers.
      function codex-nix --description 'Run Codex with Nix-provided Bubblewrap, Node.js, Python, and uv'
          nix shell --inputs-from /home/basn/nixos nixpkgs#bubblewrap nixpkgs#nodejs nixpkgs#python3 nixpkgs#uv -c bash -c 'export UV_PYTHON="$(command -v python3)"; exec npx -y @openai/codex -c "mcp_servers.nixos.command=\"nix\"" -c "mcp_servers.nixos.args=[\"run\", \"github:utensils/mcp-nixos\", \"--\"]" "$@"' codex-nix $argv
      end
    '';
    ".config/opencode/opencode.json".source = ../machines/battlestation/opencode.json;
    ".config/opencode/unifi-controller.pem".source = ../machines/battlestation/unifi-controller.pem;
  };
}
