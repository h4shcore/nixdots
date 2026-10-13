{...}: {
  home.sessionVariables = {
    EDITOR = "emacsclient -t -a 'emacs'";
    TERMINAL = "kitty";
  };
  services.udiskie = {
    enable = true;
    tray = "auto";
  };
}
