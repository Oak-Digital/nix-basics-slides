{
  faces ? 6,
  count ? 1,
}: # Added 'count' with a default of 1

let
  time = builtins.currentTime;
  mod = a: b: a - (builtins.div a b) * b;

  # We generate a roll based on the index 'i' of the list.
  # We multiply 'i' by 17 (an arbitrary prime number) and add it to the time
  # so each die evaluates to a different number.
  makeRoll = i: (mod (time + (i * 17)) faces) + 1;

  # Generate a list of results based on the 'count' parameter
  rolls = builtins.genList makeRoll count;

  # Turn the list of numbers into a readable, comma-separated string
  rollsString = builtins.concatStringsSep ", " (map toString rolls);
in
"🎲 You rolled ${toString count}d${toString faces}: [ ${rollsString} ]"
