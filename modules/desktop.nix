{...}: {
  programs = {
    niri = {
      enable = true;
    };

    hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true; # Xwayland can be disabled
    };
  };
}
