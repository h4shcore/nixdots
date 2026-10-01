{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./yazi
    ./tmux
  ];

  home.packages = with pkgs; [
    yazi
    fastfetch
    unzip
    p7zip
    ripgrep
    fish
    starship
    foot
    kitty
    eza
    btop
    cava
    wget
  ];

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };

  xdg.configFile."fish/config.fish".source = ./fish/config.fish;
  xdg.configFile."foot/foot.ini".source = ./foot/foot.ini;
  xdg.configFile."kitty/kitty.conf".source = ./kitty/kitty.conf;
}
