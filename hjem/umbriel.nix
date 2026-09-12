{
  config,
  lib,
  ...
}:
{
  services.gnome.gnome-keyring.enable = lib.mkIf config.programs.umbriel.enable true;

  hjem.users.basn = lib.mkIf config.programs.umbriel.enable {
    files = {
      ".config/umbriel/config.toml".source = ./configs/umbriel/config.toml;
      ".config/umbriel/general.toml".source = ./configs/umbriel/general.toml;
      ".config/umbriel/outputs.toml".source = ./configs/umbriel/outputs.toml;
      ".config/umbriel/input.toml".source = ./configs/umbriel/input.toml;
      ".config/umbriel/keybinds.toml".source = ./configs/umbriel/keybinds.toml;
      ".config/umbriel/layout.toml".source = ./configs/umbriel/layout.toml;
      ".config/umbriel/appearance.toml".source = ./configs/umbriel/appearance.toml;
    };
  };
}
