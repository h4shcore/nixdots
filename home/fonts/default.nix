{pkgs, ...}: {
  fonts.fontconfig = {
    enable = true;

    defaultFonts = {
      monospace = [
        "MapleMono NF"
      ];

      sansSerif = [
        "MapleMono NF"
      ];

      serif = [
        "MapleMono NF"
      ];

      emoji = [
        "Noto Color Emoji"
      ];
    };
  };

  home.packages = with pkgs; [
    noto-fonts-color-emoji
    material-symbols
    maple-mono.NF
  ];
}
