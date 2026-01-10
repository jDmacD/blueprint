{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixvim.homeModules.nixvim
  ];
  programs.helix = {
    enable = true;
    extraPackages = with pkgs; [
      nil
      nixd
      marksman
      ruff
      bash-language-server
      yaml-language-server
      terraform-ls
    ];
    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = "${pkgs.nixfmt}/bin/nixfmt";
          };
        }
      ];
    };
  };
  programs.nixvim = {
    enable = false;
    plugins = {
      # https://nix-community.github.io/nixvim/plugins/comment/index.html
      telescope.enable = true;
      lightline.enable = true;
      nvim-tree.enable = true;
      comment.enable = true;
      auto-save.enable = true;
      markdown-preview.enable = true;
      web-devicons.enable = true;
      lsp = {
        enable = true;
        inlayHints = true;
        servers = {
          yamlls = {
            enable = true;
            extraOptions = {
              settings = {
                yaml = {
                  schemas = {
                    kubernetes = "'*.yaml";
                    "http://json.schemastore.org/github-workflow" = ".github/workflows/*";
                    "http://json.schemastore.org/github-action" = ".github/action.{yml,yaml}";
                    "http://json.schemastore.org/ansible-stable-2.9" = "roles/tasks/*.{yml,yaml}";
                    "http://json.schemastore.org/kustomization" = "kustomization.{yml,yaml}";
                    "http://json.schemastore.org/ansible-playbook" = "*play*.{yml,yaml}";
                    "http://json.schemastore.org/chart" = "Chart.{yml,yaml}";
                    "https://json.schemastore.org/dependabot-v2" = ".github/dependabot.{yml,yaml}";
                    "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" =
                      "*docker-compose*.{yml,yaml}";
                    "https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json" =
                      "*flow*.{yml,yaml}";
                  };
                };
              };
            };
          };
        };
      };
    };
    opts = {
      shiftwidth = 2;
    };
    keymaps = [
      {
        action = "<cmd>Telescope find_files<CR>";
        key = "<C-s>";
        mode = "n";
        options = {
          desc = "Search using telescope";
        };
      }
      {
        action = "<cmd>:NvimTreeToggle<CR>";
        key = "<C-t>";
        mode = "n";
        options = {
          desc = "Toggle Tree";
        };
      }
    ];
    autoCmd = [
      # {
      #   event = "VimEnter";
      #   pattern = "*";
      #   command = "NvimTreeOpen";
      # }
    ];
  };
}
