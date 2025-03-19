{ ... }:

{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      command_timeout = 1000;

      battery = {
        full_symbol = "󱊣 ";
        charging_symbol = "󰂄 ";
        discharging_symbol = "󱊢 ";
        display = [
          {
            threshold = 15;
            style = "bold red";
          }
          {
            threshold = 50;
            style = "bold yellow";
          }
          {
            threshold = 100;
            style = "bold green";
          }
        ];
      };
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[✗](bold red)";
      };
      cmd_duration = {
        min_time = 500;
        show_milliseconds = true;
      };
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        truncation_symbol = "…/";
      };
      memory_usage = {
        disabled = false;
        threshold = -1;
        format = "\${symbol}[\${ram}( | \${swap})](\${style}) ";
        symbol = "🧠 ";
        style = "bold dimmed green";
      };
      time.disabled = false;
      username.show_always = true;
      package.disabled = true;
      status.disabled = false;
    };
  };
}
