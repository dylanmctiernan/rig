{
  pkgs,
  config,
  inputs,
  ...
}: let
  # Load shared configuration
  commonConfig = import ../../common-config.nix;

  # Configuration values
  gitUserName = commonConfig.dylan.name;
  gitUserEmail = commonConfig.dylan.email;
  sshSigningKey = commonConfig.dylan.sshPublicKey;
in {
  # Home manager configuration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.dylan = {
    pkgs,
    config,
    ...
  }: {
    imports = [
      inputs.sops-nix.homeManagerModules.sops
    ];

    # Sops configuration for dylbook (in home-manager)
    # Only secrets from secrets.yaml - public config is in common-config.nix
    sops = {
      defaultSopsFile = ../../../secrets.yaml;
      age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

      # Place SSH private key at default path
      secrets = {
        "dylan/ssh/private_key" = {
          path = "${config.home.homeDirectory}/.ssh/id_ed25519";
          mode = "0600";
        };
      };
    };
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



    programs.git = {
      enable = true;
      settings = {
        user.name = gitUserName;
        user.email = gitUserEmail;
        init.defaultBranch = "main";
        gpg.format = "ssh";
        gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";
      };
      signing = {
        signByDefault = true;
        key = sshSigningKey;
      };
    };

    # Create allowed_signers file for SSH signing verification
    home.file.".ssh/allowed_signers".text = ''
      ${gitUserEmail} ${sshSigningKey}
    '';

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

    # Sops: Age key should be manually managed at ~/.config/sops/age/keys.txt
    # Retrieve from Bitwarden or generate with: age-keygen -o ~/.config/sops/age/keys.txt
    # The .sops.yaml in repo root will be used when editing config.yaml in the repo

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      # Simple Lua config (converted from init.vim)
      extraLuaConfig = builtins.readFile ./files/neovim/init.lua;
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
    home.homeDirectory = "/Users/${config.home.username}";

    xdg.enable = true;

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
