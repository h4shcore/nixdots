{pkgs, ...}: {
  programs.nix-ld.enable = true;

  # Common libraries these tools tend to need; extend as you hit missing-lib errors
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    openssl
    curl
    glib
    libxml2
  ];
}
