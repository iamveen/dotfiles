{ pkgs, ... }: {
  home.username = "iamveen";
  home.homeDirectory = "/home/iamveen";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Core CLI
    bat
    delta
    eza
    fd
    jq
    ripgrep
    tree-sitter

    # Terminal & TUI
    atuin
    btop
    fzf
    lazydocker
    lazygit
    lazyjournal
    neovim
    tmux
    yazi
    zellij

    # Git & VCS
    git-cliff
    gitleaks
    jujutsu

    # Security & Analysis
    lychee
    tokei
    trivy
    vale

    # Markdown & Writing
    glow

    # Search & Rewrite
    ast-grep
    difftastic
    sd

    # Shell & Scripting
    shellcheck
    watchexec
    hyperfine

    # Data processing
    yq-go

    # Formatting
    prettier

    # Runtimes — global defaults; per-project versions via flake.nix + direnv
    nodejs
    ruby
    rustup
  ];

  programs.fish = {
    enable = true;
    loginShellInit = ''
      fish_add_path ~/.local/bin
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "Gavin Dunne";
      user.email = "g@veen.ca";
      alias = {
        st     = "status";
        ci     = "commit";
        co     = "checkout";
        di     = "diff";
        dc     = "diff --cached";
        amend  = "commit --amend";
        aa     = "add --all";
        ff     = "merge --ff-only";
        pullff = "pull --ff-only";
        noff   = "merge --no-ff";
        fa     = "fetch --all";
        pom    = "push origin master";
        b      = "branch";
        ds     = "diff --stat=160,120";
        dh1    = "diff HEAD~1";
        cb     = "rev-parse --abbrev-ref HEAD";
      };
      github.user = "iamveen";
      color.ui = "auto";
      init.defaultBranch = "main";
      core.hooksPath = "~/.config/git/hooks";
    };
  };
}
