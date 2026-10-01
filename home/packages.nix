{pkgs, inputs, ...}: {
  home.packages = with pkgs; [
    spotify
    pear-desktop
    vesktop
    equibop
    firefox
    brave-origin
    qbittorrent
    mpv
    ani-cli
    woomer
    matugen
    inputs.vivy.packages.${pkgs.stdenv.hostPlatform.system}.default # github:h4shcore/vivy
  ];
}
