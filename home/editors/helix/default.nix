{pkgs, ...}: {
  home.packages = with pkgs; [
    clang-tools # clangd + clang-format: C / C++
    rust-analyzer
    rustfmt # rust-analyzer formats via this
    gopls
    go # gopls formats via `gofmt`, bundled with the go toolchain
    haskell-language-server
    ormolu # explicit Haskell formatter (HLS's own formatting is inconsistent)
    vscode-langservers-extracted # html/css/json language servers
    typescript-language-server
    typescript
    pyright # python
    ruff
    prettier # formatter for html/css/json/js/ts
    taplo # TOML: LSP + native formatting
    nil # Nix language server
    nixpkgs-fmt # explicit Nix formatter (nil doesn't format on its own)
  ];

  programs.helix = {
    enable = true;
    settings = {
      theme = "matugen";
      editor = {
        true-color = true;
        color-modes = true;
        auto-format = true;
        line-number = "relative";
        cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };
        lsp = {
          display-color-swatches = true;
        };
        soft-wrap = {
          enable = true;
          max-wrap = 25; # max characters allowed to be wrapped over the view width
          max-indent-retain = 40; # retain up to this much indentation on wrapped lines
          wrap-indicator = "↪ "; # shown at the start of a wrapped (continuation) line
        };
      };
    };

    languages = {
      language-server = {
        clangd.command = "clangd";
        rust-analyzer.command = "rust-analyzer";
        gopls.command = "gopls";
        haskell-language-server = {
          command = "haskell-language-server-wrapper";
          args = ["lsp"];
        };
        vscode-html-language-server = {
          command = "vscode-html-language-server";
          args = ["--stdio"];
        };
        vscode-css-language-server = {
          command = "vscode-css-language-server";
          args = ["--stdio"];
        };
        vscode-json-language-server = {
          command = "vscode-json-language-server";
          args = ["--stdio"];
        };
        typescript-language-server = {
          command = "typescript-language-server";
          args = ["--stdio"];
        };
        taplo = {
          command = "taplo";
          args = ["lsp" "stdio"];
        };
        pyright = {
          command = "pyright-langserver";
          args = ["--stdio"];
        };

        ruff = {
          command = "ruff";
          args = ["server"];
        };
        nil.command = "nil";
      };

      language = [
        {
          name = "c";
          language-servers = ["clangd"];
        }
        {
          name = "cpp";
          language-servers = ["clangd"];
        }
        {
          name = "rust";
          language-servers = ["rust-analyzer"];
        }
        {
          name = "go";
          language-servers = ["gopls"];
        }
        {
          name = "haskell";
          language-servers = ["haskell-language-server"];
          formatter = {command = "ormolu";};
        }
        {
          name = "html";
          language-servers = ["vscode-html-language-server"];
          formatter = {
            command = "prettier";
            args = ["--parser" "html"];
          };
        }
        {
          name = "css";
          language-servers = ["vscode-css-language-server"];
          formatter = {
            command = "prettier";
            args = ["--parser" "css"];
          };
        }
        {
          name = "javascript";
          language-servers = ["typescript-language-server"];
          formatter = {
            command = "prettier";
            args = ["--parser" "babel"];
          };
        }
        {
          name = "typescript";
          language-servers = ["typescript-language-server"];
          formatter = {
            command = "prettier";
            args = ["--parser" "typescript"];
          };
        }
        {
          name = "toml";
          language-servers = ["taplo"];
        }
        {
          name = "json";
          language-servers = ["vscode-json-language-server"];
          formatter = {
            command = "prettier";
            args = ["--parser" "json"];
          };
        }
        {
          name = "python";
          language-servers = [
            "ruff"
            "pyright"
          ];
          formatter = {
            command = "ruff";
            args = ["format" "-"];
          };
        }
        {
          name = "nix";
          language-servers = ["nil"];
          formatter = {command = "nixpkgs-fmt";};
        }
      ];
    };
  };
}
