{pkgs, ...}: {
  fonts.fontconfig = {
    enable = true;

    defaultFonts = {
      monospace = [
        "GeistMono Nerd Font"
      ];

      sansSerif = [
        "GeistMono Nerd Font"
      ];

      serif = [
        "GeistMono Nerd Font"
      ];

      emoji = [
        "Noto Color Emoji"
      ];
    };
  };

  home.packages = with pkgs; [
    noto-fonts-color-emoji
    maple-mono.NF
  ];
}
