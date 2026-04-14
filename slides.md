---
theme: default
title: Nix onboarding
class: text-center
transition: slide-left
comark: true
duration: 50min
---

# Nix

Beginner onboarding for people who are new to Nix

- Goal: understand the mental model and understand syntax
- Format: half explanation, half exercises

---

# What problem does Nix solve?

- "It works on my machine" problems
- hidden global dependencies
- manual setup steps nobody remembers
- hard-to-reproduce dev environments

<br>

Nix treats setup as data:

- describe the environment
- let Nix build it the same way every time

---

# Language basics

Nix is:

- an expression language
- lazy by default
- mostly about producing values
- used to describe packages, shells, configs, and systems

The big idea:

> You write expressions that evaluate to values.

---

## Primitives

Common values:

```nix
"hello"
42
true
false
[ 1 2 3 ]
null
```

Useful things to notice:

- lists are space-separated, not comma-separated
- strings can interpolate values with `${...}`
- everything is an expression

---

## Let bindings

Use `let ... in ...` to name intermediate values:

```nix
let
  name = "Alex";
  count = 3;
in
"${name} has ${toString count} tasks"
```

- definitions live in `let`
- the final result comes after `in`

---

## Functions

Functions are very lightweight:

```nix
name: "Hello ${name}"
```

Call them like this:

```nix
(name: "Hello ${name}") "world"
```

You can also take an attribute set as input:

```nix
{ name, age }: "${name} is ${toString age}"
```

Or also commonly defined in let expressions

```nix
let
  sayHello = name: "Hello ${name}";
in
sayHello "Nix"
# "Hello Nix"
```

---

## Attribute sets (attrset)

Attribute sets are Nix's object-like structure:

```nix
{
  name = "dice";
  faces = 6;
  enabled = true;
}
```

- Closely related to json or JS objects

Why they matter:

- packages are usually described as attribute sets
- flakes are mostly structured attribute sets
- config in Nix is often "just nested attrsets"

---

## Attribute sets (attrset)

```nix
{
  name = "dice";
  faces = 6;
  enabled = true;
  roll = times: "Rolling ${toString times}d6"
}
```

Attribute sets may contain functions or any other value

---

## Builtins

Nix comes with built-in functions:

```nix
builtins.toString 42
builtins.length [ 1 2 3 ]
builtins.currentSystem
```

For learning today, we will also use:

```nix
builtins.currentTime
```

That one is intentionally impure, which makes it good for a dice exercise.

---

# Exercise 1: Roll the dice

Write a Nix expression that returns a string like:

```text
🎲 You rolled a 4!
```

Rules:

- use `builtins.currentTime`
- produce a number from 1 to 6
- return a string

Hint:

- Nix has division, but no modulo operator

```nix
let
  time = builtins.currentTime;
  mod = a: b: a - (builtins.div a b) * b;
```

---

# Solution 1: Roll the dice

```nix
let
  time = builtins.currentTime;
  mod = a: b: a - (builtins.div a b) * b;
  roll = (mod time 6) + 1;
in
"🎲 You rolled a ${toString roll}!"
```

Teaching points:

- `let/in` for small calculations
- helper function with `mod = a: b: ...`
- string interpolation with `${...}`
- impure inputs change the result over time

---

# Bonus: parameterize the dice

Same idea, but now as a function:

```nix
{ faces ? 6 }:
let
  time = builtins.currentTime;
  mod = a: b: a - (builtins.div a b) * b;
  roll = (mod time faces) + 1;
in
"🎲 You rolled a ${toString roll}!"
```

- `{ faces ? 6 }` means "attrset argument with a default"
- this is often how Nix files become configurable

---

# Shells

One of the most practical uses of Nix:

- define project tools in a file
- enter the shell
- get the exact tools and versions you need

Think of `shell.nix` / `mkShell` as:

> "Give me a reproducible project terminal."

---

## Shell example

```nix
let
  pkgs = import <nixpkgs> { };
in
pkgs.mkShell {
  packages = [
    pkgs.nodejs
    pkgs.pnpm
  ];
}
```

Then enter it with:

```bash
nix-shell
```

---

# Exercise 2: `shell.nix`

Write a `shell.nix` that gives you:

- `bash`
- `git`
- `jq`

Stretch goal:

- add a `shellHook` that prints `Entered Nix shell`

---

# Solution 2: `shell.nix`

```nix
let
  pkgs = import <nixpkgs> { };
in
pkgs.mkShell {
  packages = [
    pkgs.bash
    pkgs.git
    pkgs.jq
  ];

  shellHook = ''
    echo "Entered Nix shell"
  '';
}
```

Teaching points:

- `pkgs` is usually imported once and reused
- `packages` is just a list of tools
- `shellHook` runs when the shell starts

---

# Custom scripts

You can put your own commands inside the shell too.

Why this is useful:

- avoid long copy-pasted shell commands
- give the team a shared command surface
- keep helper scripts versioned with the project

Also important:

- Nix is lazy
- a value is only evaluated if something needs it

---

## Example: add a custom command

```nix
let
  pkgs = import <nixpkgs> { };

  hello-script = pkgs.writeShellScriptBin "say-hello" ''
    echo "hello from a nix-managed script"
  '';
in
pkgs.mkShell {
  packages = [
    hello-script
  ];
}
```

After entering the shell:

```bash
say-hello
```

---

# Exercise 3: Custom script inside shell

Add a custom script to your shell called `roll-the-dice`.

Goal:

- the command should be available inside the shell
- it can print a fixed message first
- stretch goal: have it evaluate one of the dice Nix files

Hint:

- use `pkgs.writeShellScriptBin`

---

# Solution 3: Custom script inside shell

```nix
let
  pkgs = import <nixpkgs> { };

  roll-the-dice = pkgs.writeShellScriptBin "roll-the-dice" ''
    echo "Rolling..."
    nix-instantiate --eval ./rtd.nix
  '';
in
pkgs.mkShell {
  packages = [
    pkgs.nix
    roll-the-dice
  ];
}
```

Why `pkgs.nix` is included:

- the custom script calls `nix eval`
- the shell should contain the tools the script needs

---

# Nix store

The Nix store is usually:

```text
/nix/store
```

What lives there:

- packages
- build outputs
- scripts
- dependencies

Important properties:

- paths are immutable
- content gets unique hashed paths
- different versions can coexist

---

# Derivations

A derivation is the low-level build recipe Nix uses.

Mental model:

- inputs
- builder
- build steps
- output path in the store

Most of the time you use helpers like `stdenv.mkDerivation` or `mkShell`,
but under the hood this is the core idea.

---

## Bare-bones derivation

```nix
let
  pkgs = import <nixpkgs> { };
in
builtins.derivation {
  name = "bare-metal-hello";
  system = builtins.currentSystem;
  builder = "${pkgs.bash}/bin/bash";
  args = [
    "-c"
    "echo 'Hello from bare metal Nix!' > $out"
  ];
}
```

Creates a file with text (show build `nix-build ./bare-bones.nix`)

Takeaway:

- derivations are not magic
- they are structured build instructions

---

# Flakes

Flakes are a more standardized way to structure Nix projects.

Useful mental model:

- inputs: what this project depends on
- outputs: what this project exposes

Common outputs:

- `packages`
- `devShells`
- `apps`
- `checks`

<br />

> a flake is mostly an attribute set with a specific structure

---

## Tiny flake shape

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs }: {
    # packages, shells, apps, checks...
  };
}
```

Why teams like flakes:

- explicit inputs
- better sharing
- common project entrypoints

---

# Devenv

[`devenv`](https://devenv.sh/) builds on Nix to make developer environments easier.

Why people like it:

- friendlier UX than raw Nix
- easy services like databases and queues
- good fit for local development

Think of it as:

> "Nix for development environments, with batteries included."

---

# Devenv downsides

- magic
- version/debugging issues can cross tool boundaries

```nix
# devenv.nix
{
  services.postgres = {
    enable = true;
  };
}
```

```nix
# flake.nix
{
  inputs = {
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
  };
  outputs =
    { self, nixpkgs, devenv, systems, ... }@inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
      });

      devShells = forEachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };
        in
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              ./devenv.nix
            ];
          };
        }
      );
    };
}
```

---

# Services flake

flake `github:juspay/services-flake`

- Pure

```nix
{
  # 1. Add the inputs
  inputs.process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
  inputs.services-flake.url = "github:juspay/services-flake";
  #...
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # 2. Import the flake-module
        inputs.process-compose-flake.flakeModule
      ];
      perSystem = { ... }: {
        # 3. Create the process-compose configuration, importing services-flake
        process-compose."myservices" = {
          imports = [
            inputs.services-flake.processComposeModules.default
          ];
        };
      }
    };
}
```

---

# flake.parts

[`flake-parts`](https://flake.parts/) helps split large flakes into smaller pieces.

Why it exists:

- big `flake.nix` files get messy
- teams want reusable modules and conventions

Mental model:

- plain flakes work fine
- `flake-parts` helps when the structure starts getting too large

Use it when complexity justifies it, not on day one.

---

# What to remember

- Nix is an expression language that produces values
- `shell.nix` and `mkShell` are the fastest practical setup
- the Nix store gives immutability and reproducibility
- derivations are build recipes
- flakes add a standard project structure
- higher-level tools like `devenv` help, but fundamentals matter

---

# Next commands to try

```bash
nix-instantiate --eval ./rtd-1.nix
nix-instantiate --eval ./rtd-2.nix --arg faces 20
nix-instantiate --eval ./rtd-3.nix --arg faces 20 --arg count 4
nix-instantiate ./bare-bones.nix
nix repl
```

Use the deck as a map:

- expressions
- shells
- scripts
- store
- derivations
- flakes
