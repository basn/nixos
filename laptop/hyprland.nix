{ unstablePkgs, ... }:
{
  programs = {
    hyprland = {
      enable = true;
      package = unstablePkgs.hyprland;
    };
  };
}
