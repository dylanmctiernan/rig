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
