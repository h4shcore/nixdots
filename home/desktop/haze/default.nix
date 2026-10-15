{ inputs, ... }:
{
  imports = [ inputs.haze.homeModules.default ];

  programs.haze.enable = true;
  # programs.haze.systemd.enable = true;   # run as a user service instead of spawn-at-startup
  # programs.haze.installFonts = false;    # if you manage fonts yourself
}
