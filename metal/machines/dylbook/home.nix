{pkgs, ...}: {
  # Home manager configuration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.dylan = {
    pkgs,
    config,
    ...
  }: {
    programs.zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
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
      initExtra = ''
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
      userName = "Dylan McTiernan";
      userEmail = "dylan@mctiernan.io";
      signing = {
        signByDefault = true;
        key = "9CC2B68A16FF0C89";
      };
      extraConfig = {
        gpg.program = "${pkgs.gnupg}/bin/gpg";
      };
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    # Firefox configuration (Firefox installed via Homebrew on macOS)
    # Create policies.json to auto-import Caddy CA certificate
    home.file."Library/Application Support/Firefox/Policies/policies.json".text = builtins.toJSON {
      policies = {
        Certificates = {
          Install = [
            (builtins.readFile ../../caddy-ca.crt)
          ];
        };
      };
    };

    # Sops configuration - link age keys and config
    home.file.".config/sops/age/keys.txt" = {
      text = ''
        # Personal age key for mac.lab infrastructure
        # created: 2025-12-31T16:59:43-05:00
        # public key: age1fzrthms7a20xu8s05p8904tneet5xzeh4jkkq724q0mxz9wtau0s3gwfga
        AGE-SECRET-KEY-1QUW7PSKKSW7SQXL0QRSALWA8KDXF2MC22REEQML5HHZ57NLKAMEQHM72E2
      '';
      force = true;
    };

    # Link .sops.yaml to home directory for convenience
    home.file.".sops.yaml" = {
      source = ../../../.sops.yaml;
      force = true;
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
      just

      # nix
      nil
      nixd
      colmena
    ];

    home.username = "dylan";
    home.homeDirectory = "/Users/dylan";

    xdg.enable = true;

    xdg.configFile = {
      "nvim/init.vim".source = ./files/neovim/init.vim;
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
