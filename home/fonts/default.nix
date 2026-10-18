{ pkgs, ... }: {
  fonts.fontconfig = {
    enable = true;

    defaultFonts = {
      monospace = [
        "CaskaydiaCove NF"
        "Symbols Nerd Font Mono"
      ];

      sansSerif = [
        "DejaVu Sans"
      ];

      serif = [
        "DejaVu Serif"
      ];

      emoji = [
        "Noto Color Emoji"
      ];
    };
  };

  home.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    nerd-fonts.symbols-only
    noto-fonts-color-emoji
    material-symbols
  ];
}
