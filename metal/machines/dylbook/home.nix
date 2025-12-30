{pkgs, ...}: {
  # Home manager configuration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.dylan = {pkgs, ...}: {
    programs.zsh = {
      enable = true;
      syntaxHighlighting.enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "sudo"
          "mix-fast"
        ];
      };
      initContent = ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
      '';
    };

    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {};
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [
        "--cmd cd"
      ];
    };

    programs.eza = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.bat = {
      enable = true;
    };

    programs.gpg = {
      enable = true;
    };

    programs.git = {
      enable = true;
      signing.signByDefault = true;
      signing.key = null;
      settings.user.name = "Dylan McTiernan";
      settings.user.email = "dylan@mctiernan.io";
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
    };

    home.packages = with pkgs; [
      # tools
      xh # http
      fx # json
      fd # find
      sd # sed
      procs # ps
      ffmpeg
      tokei # loc
      oha # simple load testing
      wrk # fast simple load testing
      drill # complex load testing
      hyperfine # command benchmarking

      # dev
      nodejs_22
      pnpm
      bun
      claude-code
      beam28Packages.elixir_1_19
      beam28Packages.erlang
      python3
      uv
      go
      postgresql
      flyctl
      opentofu
      gh
      nodePackages_latest.vercel
      sops
      age
      bws
      trufflehog

      # nix
      nil
      nixd
      alejandra
    ];

    home.username = "dylan";
    home.homeDirectory = "/Users/dylan";

    xdg.enable = true;

    home.file = {
      ".config/nvim/init.vim".source = ./files/neovim/init.vim;
    };

    home.sessionVariables = {
      FX_LANG = "python3";
      EDITOR = "nvim";
      ERL_AFLAGS = "-kernel shell_history enabled";
    };

    home.sessionPath = [];

    home.stateVersion = "25.05";

    programs.home-manager.enable = true;
  };
}
