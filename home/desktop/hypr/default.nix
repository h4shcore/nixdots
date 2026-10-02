{ config, ... }:
let
  # false: files are copied into the Nix store (pure, needs a rebuild per edit)
  # true:  ~/.config/hypr points straight at your repo, so edits apply with a reload
  liveEdit = false;

  # Path to your flake repo, only used when liveEdit = true
  repoPath = "${config.home.homeDirectory}/nixos";

  src = path:
    if liveEdit
    then config.lib.file.mkOutOfStoreSymlink "${repoPath}/home/desktop/hypr/${path}"
    else ./. + "/${path}";
in
{
  xdg.configFile = {
    "hypr/hyprland.lua".source = src "hyprland.lua";
    "hypr/conf".source = src "conf";
  };
}
