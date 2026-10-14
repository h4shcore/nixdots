{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    terminal = "tmux-256color";
    historyLimit = 100000;
    clock24 = true;
    mouse = true;
    escapeTime = 0;
    baseIndex = 1;
    keyMode = "vi";
    sensibleOnTop = false;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      # vim-tmux-navigator
      resurrect
      continuum
    ];
    extraConfig = ''
      # Prefix
      unbind C-b
      set -g prefix C-Space
      bind C-Space send-prefix

      # Splits
      # bind " split-window -h
      # bind % split-window -v

      # Reload
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

      # Vim Pane Navigation
      # bind -n M-h select-pane -L
      # bind -n M-j select-pane -D
      # bind -n M-k select-pane -U
      # bind -n M-l select-pane -R

      # Resize
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Status
      set -g status-position bottom
      set -g status-interval 5
      set -g status-left-length 30
      set -g status-right-length 60

      # Better Window Names
      setw -g automatic-rename on
      setw -g automatic-rename-format "#{b:pane_current_path}"

      # Start Windows at 1
      setw -g pane-base-index 1

      # Load matugen colors
      source-file -q ~/.config/tmux/matugen-colors.conf
    '';
  };
}
