let
  # We still need Nixpkgs, but ONLY to grab a shell binary.
  pkgs = import <nixpkgs> { };
in
builtins.derivation {
  # 1. Every derivation needs a name
  name = "bare-metal-hello";

  # 2. It needs to know what architecture it is building for
  system = builtins.currentSystem;

  # 3. The builder MUST be an absolute path to an executable.
  # We use string interpolation to get the path to bash in the Nix store.
  builder = "${pkgs.bash}/bin/bash";

  # 4. Arguments passed to the builder.
  # We tell bash to run a command (-c) that writes a string to $out.
  args = [
    "-c"
    "echo 'Hello from bare metal Nix!' > $out"
  ];
}
