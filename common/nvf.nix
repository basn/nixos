{ pkgs, ... }:
{
  programs = {
    nvf = {
      enable = true;
      settings = {
        vim = {
          extraPlugins = {
            "onedarkpro.nvim" = {
              package = pkgs.vimPlugins.onedarkpro-nvim;
              setup = ''
                vim.cmd("colorscheme onedark_dark")
              '';
            };
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
                type = [ "nixfmt" ];
              };
              lsp = {
                enable = true;
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
