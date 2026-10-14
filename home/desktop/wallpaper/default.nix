{pkgs, ...}: let
  wall-backdrop = pkgs.writeShellApplication {
    name = "wall-backdrop";
    runtimeInputs = [pkgs.imagemagick]; # awww is found on PATH from your packages.nix
    text = ''
      out="''${XDG_CACHE_HOME:-$HOME/.cache}/wall-backdrop.jpg"

      # login: re-show the last blurred image (the backdrop daemon starts empty)
      if [ "''${1:-}" = "--restore" ]; then
        [ -f "$out" ] && exec awww img --namespace backdrop --transition-type none "$out"
        exit 0
      fi

      img="''${1:?usage: wall-backdrop <image> | --restore}"
      magick "$img" -resize 50% -blur 0x16 -modulate 70,110 "$out"
      exec awww img --namespace backdrop --transition-type fade "$out"
    '';
  };
in {
  home.packages = [wall-backdrop];
}
