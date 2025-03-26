{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autocd = true;
    autosuggestion.enable = true;
    dotDir = ".config/zsh";
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
    syntaxHighlighting.enable = true;
    initExtra = ''
      setopt longlistjobs           # display PID when suspending processes
      setopt notify                 # report status of background jobs
      setopt auto_pushd             # make cd push the old directory onto the stack
      setopt nobeep
      setopt pushd_ignore_dups
      setopt noglobdots             # * not match dotfiles
      setopt noshwordsplit          # zsh style word splitting
      setopt interactivecomments    # accept comments on interactive shell
      setopt completeinword         # complete not just at the end

      mpva() {
          case "$1" in
              *.m3u|*.m3u8)
                  playlist="$1"
                  shift
                  mpv --no-video --no-cookies --playlist="$playlist" $@
                  ;;
              *)
                  mpv --no-video --no-cookies $@
                  ;;
          esac
      }
      mpv() {
          case "$1" in
              *.m3u|*.m3u8)
                  playlist="$1"
                  shift
                  mpv --playlist="$playlist" $@
                  ;;
              *)
                  mpv $@
                  ;;
          esac
      }
      meteo() {
          curl -fsS https://wttr.in/"$1"?F
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
