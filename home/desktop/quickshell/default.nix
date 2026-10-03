{ config, pkgs, ... }:
{
  home.file.".config/quickshell/notch" = {
    source = ./notch;
    recursive = true;
  };
}
