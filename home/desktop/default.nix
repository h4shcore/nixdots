{pkgs, inputs, ...}: {
  home.packages = with pkgs; [
    awww
    playerctl
    brightnessctl
    # dunst
    libnotify
    fuzzel
    # waybar
    cliphist
    wl-clipboard
    pavucontrol
    # xwayland-satellite
    (let pkgs = import inputs.nixpkgs-xwayland-satellite-0-8-1 { system = "x86_64-linux"; }; in pkgs.xwayland-satellite)
    pywalfox-native
    quickshell
    grim
    slurp
    satty
  ];

  imports = [
    ./theme.nix

    ./fuzzel
    # ./niri
    ./hypr
    ./quickshell
  ];

  xdg.configFile."waybar/config.jsonc".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;
  xdg.configFile."matugen".source = ./matugen;
}
