{inputs, ...}: {
  imports = [
    inputs.nix-doom-emacs-unstraightened.homeModule
  ];
  nixpkgs.overlays = [
    inputs.nix-doom-emacs-unstraightened.overlays.default
  ];
  programs.doom-emacs = {
    enable = true;
    doomDir = ./doom.d;
  };
}
