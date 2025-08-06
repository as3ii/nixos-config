{ config, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autocd = true;
    autosuggestion.enable = true;
    dotDir = "${config.xdg.configHome}";
    history = {
      append = true;
      extended = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      path = "$HOME/.cache/zsh/history";
      save = 1000000;
      saveNoDups = true;
      share = true;
      size = 100000;
    };
    historySubstringSearch.enable = true;
    syntaxHighlighting = {
      enable = true;
      styles = {
        comment = "fg=#b2f5bf"; # light green
      };
    };
    completionInit = ''
      autoload -U compinit && compinit
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list "" 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion::(^approximate*):*:functions' ignored-patterns '_*'
      zstyle ':completion:*:default' list-colors ${"\${(s.:.)LS_COLORS}"}
    '';
    initContent = ''
      setopt longlistjobs           # display PID when suspending processes
      setopt notify                 # report status of background jobs
      setopt auto_pushd             # make cd push the old directory onto the stack
      setopt nobeep
      setopt pushd_ignore_dups
      setopt noglobdots             # * not match dotfiles
      setopt noshwordsplit          # zsh style word splitting
      setopt interactivecomments    # accept comments on interactive shell
      setopt completeinword         # complete not just at the end

      bindkey -e                    # defaults to emacs mode
      bindkey "^[[2~" overwrite-mode        # insert
      bindkey "^[[3~" delete-char           # delete
      bindkey "^[[H" beginning-of-line      # home
      bindkey "^[[F" end-of-line            # end
      bindkey "^[OH" beginning-of-line      # home, alternative
      bindkey "^[OF" end-of-line            # end, alternative
      bindkey "^[[A" up-line-or-search      # up
      bindkey "^[[B" down-line-or-search    # down
      bindkey "^[[C" forward-char           # right
      bindkey "^[[D" backward-char          # left
      bindkey "^[[1;5A" beginning-of-line   # ctrl+up
      bindkey "^[[1;5B" end-of-line         # ctrl+down
      bindkey "^[[1;5C" forward-word        # ctrl+right
      bindkey "^[[1;5D" backward-word       # ctrl+left

      mpva() {
          case "$1" in
              *.m3u|*.m3u8)
                  playlist="$1"
                  shift
                  env mpv --no-video --no-cookies --playlist="$playlist" $@
                  ;;
              *)
                  env mpv --no-video --no-cookies $@
                  ;;
          esac
      }
      mpv() {
          case "$1" in
              *.m3u|*.m3u8)
                  playlist="$1"
                  shift
                  env mpv --playlist="$playlist" $@
                  ;;
              *)
                  env mpv $@
                  ;;
          esac
      }
      meteo() {
          curl -fsS "${"https://wttr.in/\${1}?F"}"
      }
      j() {
          mkdir -p "/tmp/$USER/"
          OUTPUT_FILE="$(mktemp -p "/tmp/$USER" "tmp-joshuto-cwd-XXXXX")"
          env joshuto --output-file "$OUTPUT_FILE" $@
          exit_code=$?

          case "$exit_code" in
              0)  # regular exit
                      ;;
              101)# output contains current directory
                  cd "$(cat "$OUTPUT_FILE")"
                  ;;
              102)# output selected files
                  ;;
              *)  # other
                  return $exit_code
                  ;;
          esac
      }
    '';
    envExtra = "";
  };
}
