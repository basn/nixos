{ pkgs, config, ... }:
{
  programs = {
    neovim = {
      defaultEditor = true;
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
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
                enable = config.programs.nvf.settings.vim.languages.enableTreesitter;
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
              treesitter.enable = config.programs.nvf.settings.vim.languages.enableTreesitter;
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
