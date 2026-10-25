{ inputs, ... }:
{
  imports = [ inputs.island.homeManagerModules.default ];
  programs.island = {
    enable = true;
    settings = {
      wallpapers.dir = "~/Pictures/wallpapers";
      launcher.terminal = [ "kitty" ];
      clipboard.watch = true;
    };
  };
}
