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

      # Modern Lua config (2025 best practices)
      extraLuaConfig = ''
        -- General options
        vim.opt.number = true
        vim.opt.relativenumber = true
        vim.opt.mouse = 'a'
        vim.opt.clipboard = 'unnamedplus'
        vim.opt.cursorline = true
        vim.opt.hidden = true
        vim.opt.splitbelow = true
        vim.opt.splitright = true
        vim.opt.title = true
        vim.opt.wildmenu = true
        vim.opt.inccommand = 'split'
        vim.opt.termguicolors = true

        -- Indentation (editorconfig-aware with plugin)
        vim.opt.expandtab = true
        vim.opt.shiftwidth = 2
        vim.opt.tabstop = 2
        vim.opt.smartindent = true

        -- Whitespace visibility
        vim.opt.list = true
        vim.opt.listchars = { tab = '>·', space = '·', trail = '·' }

        -- Search
        vim.opt.ignorecase = true
        vim.opt.smartcase = true

        -- Leader key
        vim.g.mapleader = ' '

        -- Keymaps
        local keymap = vim.keymap.set

        -- Window navigation
        keymap('n', '<C-h>', '<C-w>h')
        keymap('n', '<C-j>', '<C-w>j')
        keymap('n', '<C-k>', '<C-w>k')
        keymap('n', '<C-l>', '<C-w>l')

        -- Stay in indent mode
        keymap('v', '<', '<gv')
        keymap('v', '>', '>gv')

        -- LSP keymaps
        vim.api.nvim_create_autocmd('LspAttach', {
          callback = function(args)
            local opts = { buffer = args.buf }
            keymap('n', 'gd', vim.lsp.buf.definition, opts)
            keymap('n', 'K', vim.lsp.buf.hover, opts)
            keymap('n', '<leader>rn', vim.lsp.buf.rename, opts)
            keymap('n', '<leader>ca', vim.lsp.buf.code_action, opts)
            keymap('n', 'gr', vim.lsp.buf.references, opts)
          end,
        })

        -- Plugin configs
        require('catppuccin').setup({ flavour = 'mocha' })
        vim.cmd.colorscheme('catppuccin')

        require('nvim-treesitter.configs').setup({
          highlight = { enable = true },
          indent = { enable = true },
        })

        require('lualine').setup({ options = { theme = 'catppuccin' } })
        require('gitsigns').setup()
        require('nvim-autopairs').setup()
        require('Comment').setup()

        -- LSP setup
        local lspconfig = require('lspconfig')
        local capabilities = require('cmp_nvim_lsp').default_capabilities()

        lspconfig.nil_ls.setup({ capabilities = capabilities })
        lspconfig.lua_ls.setup({ capabilities = capabilities })
        lspconfig.tsserver.setup({ capabilities = capabilities })
        lspconfig.pyright.setup({ capabilities = capabilities })
        lspconfig.rust_analyzer.setup({ capabilities = capabilities })
        lspconfig.gopls.setup({ capabilities = capabilities })
        lspconfig.elixirls.setup({
          cmd = { "elixir-ls" },
          capabilities = capabilities
        })

        -- Completion
        local cmp = require('cmp')
        cmp.setup({
          snippet = {
            expand = function(args)
              require('luasnip').lsp_expand(args.body)
            end,
          },
          mapping = cmp.mapping.preset.insert({
            ['<C-b>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<C-Space>'] = cmp.mapping.complete(),
            ['<CR>'] = cmp.mapping.confirm({ select = true }),
          }),
          sources = cmp.config.sources({
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
          }, {
            { name = 'buffer' },
            { name = 'path' },
          })
        })
      '';

      plugins = with pkgs.vimPlugins; [
        catppuccin-nvim
        (nvim-treesitter.withPlugins (p: [
          p.nix p.lua p.typescript p.javascript p.python
          p.rust p.go p.elixir p.yaml p.json p.markdown p.bash
        ]))
        nvim-lspconfig
        nvim-cmp
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        luasnip
        cmp_luasnip
        gitsigns-nvim
        lualine-nvim
        nvim-web-devicons
        nvim-autopairs
        comment-nvim
        editorconfig-nvim
      ];

      extraPackages = with pkgs; [
        # LSP servers
        nil
        lua-language-server
        nodePackages.typescript-language-server
        pyright
        rust-analyzer
        gopls
        elixir-ls

        # Formatters
        alejandra
        stylua

        # Tools
        ripgrep
        fd
      ];
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
