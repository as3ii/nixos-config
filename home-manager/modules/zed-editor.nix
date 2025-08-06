{ pkgs, lib, ... }:

{
  programs.zed-editor = {
    enable = true;
    extensions = [ "nix" "ruff" "toml" ];
    extraPackages = with pkgs; [
      nil # nix
      ruff # python
      shellcheck # bash
      rust-analyzer # rust
    ];
    userKeymaps = [
      {
        context = "Workspace";
        bindings = {
          ctrl-tab = "workspace::ActivateNextPane";
          ctrl-shift-tab = "workspace::ActivatePreviousPane";
        };
      }
      {
        context = "Editor";
        bindings = {
          f2 = "workspace::Save";
          f3 = "editor::Rename";
        };
      }
      {
        context = "Pane";
        bindings = { };
      }
    ];
    userSettings = {
      node = {
        path = lib.getExe pkgs.nodejs;
        npm_path = lib.getExe' pkgs.nodejs "npm";
      };
      lsp = {
        nix.binary.path_lookup = true;
        ruff.initialization_options.settings = {
          lineLength = 100;
          lint = {
            # default select = [ E4 E7 E9 F ]
            extendSelect = [ "E" "W" "I" "N" "D" "UP" "ASYNC" "S" "BLE" "B" "A" "COM" "C4" "DTZ" "EM" "FA" "ISC" "ICN" "LOG" "G" "PIE" "PYI" "Q" "RSE" "RET" "SLF" "SIM" "TID" "TCH" "INT" "ARG" "TD" "FIX" "ERA" "PL" "TRY" "PERF" "FURB" "DOC" "RUF" ];
            extendIgnore = [ "UP017" "UP032" ];
          };
          codeAction.fixViolation.enable = false;
        };
      };
      language = {
        Python = {
          language_server = [ "ruff" ];
          formatter = {
            language_server.name = "ruff";
            code_action = {
              "source.organizeImports.ruff" = true;
              "source.fixAll.ruff" = true;
            };
          };
        };
      };
      language_model = {
        ollama = {
          api_url = "http://localhost:11434";
          available_model = [
            {
              name = "";
              display_name = "";
              max_tokens = 32768;
            }
          ];
        };
      };
      agent = {
        version = 2;
        default_model = {
          provider = "ollama";
          model = "";
        };
      };
      vim_mode = true;
      vim = {
        use_system_clipboard = "on_yank";
        use_smartcase_find = true;
      };
      relative_line_number = true;
      scrollbar.show = "auto";
      telemetry.metrics = false;
      load_direnv = "shell_hook";
      auto_signature_help = true;
      diagnostic.inline.enabled = true;
      auto_update = false;
      format_on_save = "off";
      hour_format = "hour24";
      show_whitespaces = "boundary";
      #soft_wrap = "bounded";
      search.regex = true;
      wrap_guides = [ 80 ];
      ui_font_size = 16;
      buffer_font_size = 16;
      # Available for Linux* from v0.187.4-pre
      # *: still incomplete, see https://github.com/zed-industries/zed/issues/12176
      buffer_font_features = {
        liga = false;
        calt = false;
      };
      theme = {
        mode = "system";
        light = "Ayu Light";
        dark = "Ayu Dark";
      };
    };
  };
}
