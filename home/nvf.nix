{ pkgs, ... }:
{
  programs = {
    nvf = {
      enable = true;
      settings = {
        vim = {
          lazy.plugins = {
            "onedarkpro.nvim" = {
              package = pkgs.vimPlugins.onedarkpro-nvim;
            };
          };
          theme = {
            enable = true;
            name = "onedark";
            style = "darker";
          };
          lsp = {
            enable = true;
          };
          languages = {
            enableFormat = true;
            enableTreesitter = true;
            nix = {
              enable = true;
              treesitter = {
                enable = true;
              };
              extraDiagnostics.enable = true;
              format = {
                enable = true;
                type = "alejandra";
              };
            };
            yaml = {
              enable = true;
              lsp.enable = true;
              treesitter.enable = true;
            };
          };
          statusline = {
            lualine = {
              enable = true;
            };
          };
          ui = {
            colorizer.enable = true;
            noice.enable = true;
          };
          options = {
            smartindent = true;
            shiftwidth = 2;
            tabstop = 2;
          };
          git = {
            enable = true;
          };
          searchCase = "smart";
          autocomplete.blink-cmp = {
            enable = true;
            friendly-snippets.enable = true;
          };
        }; 
      };
    };
  };
}
