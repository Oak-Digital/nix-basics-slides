let
  # Grab the current Unix timestamp (requires the --impure flag to work)
  time = builtins.currentTime;

  # Nix doesn't have a built-in modulo operator, so we have to define our own
  mod = a: b: a - (builtins.div a b) * b;

  # Calculate a number between 1 and 6
  roll = (mod time 6) + 1;
in
"🎲 You rolled a ${toString roll}!"
