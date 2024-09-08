# Nix: from zero to something

![The Declarative Trinity](./pics/the-declarative-trinity.webp)

---

TODO MERMAID GRAPHS

# Disclaimer(todo)

>- "But I can do `x` with `y` too!"
>- My approach with Nix is orthodox, but partial integration is possible
>- Many personal opinions
>- I'll sacrifice some precision for better digestibility
>- This starts from a fork: <https://github.com/aciceri/nixos-devops-talk>

# Nix as a Language (1/2)

>- **declarative**: There is no notion of executing sequential steps.
Dependencies between operations are established only through data.
>- **pure**: Values cannot change during computation.
Functions always produce the same output if their input does not change.
>- **functional**: Functions are like any other value.
Functions can be assigned to names, taken as arguments, or returned by functions.

## Nix as a Language (2/2)

>- **lazy**: Values are only computed when they are needed.
>- **dynamically typed**: Type errors are only detected when expressions are evaluated.

---

Before we dive into derivations, let's cover some key language features
that are essential for understanding Nix expressions and flakes.

---

## Attribute Sets

   Attribute sets are like dictionaries or key-value pairs.
They're defined using curly braces:

   ```nix
   { 
     name = "example";
     value = 42;
   }
   ```

---

## Let Expressions

   `let` bindings allow you to create local variables:

   ```nix
   let 
     x = 1;
     y = 2;
   in
     x + y  # Returns 3
   ```

## With Expressions

   `with` brings an attribute set's attributes into scope:

   ```nix
   let set = { a = 1; b = 2; };
   in with set; a + b  # Returns 3
   ```

## Functions

   Functions are defined using a colon. The syntax is `argument: body`:

   ```nix
   x: x + 1  # A function that takes x and returns x + 1
   ```

   Functions can also take attribute sets as arguments:

   ```nix
   { a, b }: a + b  # A function that takes an attrset with 'a' and 'b' keys
   ```

## Function Arguments with Defaults

   In Nix, function arguments can have default values. If an argument is not
  provided during the function call, the default value is used.

   ```nix
   { x ? 10 }: x + 5  # A function with a default value for x
   ```

   Calling this function with no arguments will return `15` because `x`
  defaults to `10`.

## Function Application

   Functions are called by putting the argument after the function,
  separated by a space:

   ```nix
   (x: x + 1) 5  # Returns 6
   ```

   For functions taking attribute sets:

   ```nix
   ({ a, b }: a + b) { a = 1; b = 2; }  # Returns 3
   ```

## Import

   The `import` function is used to load Nix expressions from files or other
  sources. It can be used to import files directly or to pull in the
  Nix Packages collection (nixpkgs).

   ```nix
   let
     myModule = import ./path/to/module.nix;
   in
     myModule.someAttribute
   ```

## Importing `nixpkgs`

   The expression `<nixpkgs>` is a shorthand to refer to the Nix Packages
  collection (it's a path)

   ```nix
   let
     pkgs = import <nixpkgs> {};
   in
     pkgs.hello  # Refers to the 'hello' package from nixpkgs
   ```

## Using Import with Default Arguments

   ```nix
   { pkgs ? import <nixpkgs> {} }: 
   pkgs.hello
   ```

  Useful to override the pkgs (e.g. pin to a specific version,
  different from the default one)

# Derivation

The core building block that describes how to build a software component.
It's a low-level, immutable representation of a build process, which tells Nix exactly
what to do to produce a specific output.

## A very simple derivation

```nix
# simple.nix
{ pkgs ? import <nixpkgs> { } }:
pkgs.stdenv.mkDerivation {
  name = "simple";
  src = ./.;
  installPhase = ''
    mkdir $out
  '';
}
```

---

To build this derivation, you would use the command:

```bash
nix-build simple.nix
```

```text
...
this derivation will be built:
  /nix/store/ymf3swd54jlji0z3a0qbw1f9rxl4cgc2-simple.drv
...
```

---

We can navigate inspect a derivation:

```bash
nix derivation show /nix/store/ymf3swd54jlji0z3a0qbw1f9rxl4cgc2-simple.drv \
| jq '."/nix/store/ymf3swd54jlji0z3a0qbw1f9rxl4cgc2-simple.drv"'
```

## The `.drv` File

A `.drv` file contains:

- **Build Instructions**: How to fetch, unpack, build, and install the package.
- **Dependencies**: The dependencies required for the build, including other
packages and build tools.
- **Source Information**: Where to find the source code or files needed for
the build.
- **Phases**: Various build phases like `unpackPhase`, `patchPhase`, `buildPhase`,
`installPhase`, etc.
- **Output Paths**: Paths where the build outputs are placed in the Nix store.
- ... other "less interesting" things

## Derivation path

```bash
/nix/store/<hash>-<name>
```

The `<hash>` part of the path is derived from multiple inputs that make up the derivation.
This ensures that the derivation is deterministic,
meaning that if all inputs are the same, the resulting derivation will have the same hash
and the same store path.

---

### The `<hash>` is based on: (1/2)

- **Source code or inputs**: This includes the source files or URLs used to build the derivation.
- **Build instructions**: The Nix expression itself (the contents of the default.nix or similar)
that specifies how to build the derivation, including all phases like configurePhase, buildPhase,
 and installPhase.
- **Build environment**: This includes the specific versions of the dependencies, compilers, and
libraries used to build the derivation. Even slight changes in the environment
(e.g., different versions of dependencies) will result in a different hash.

---

### The `<hash>` is based on: (2/2)

- **System architecture**: The architecture (e.g., x86_64-linux, aarch64-linux) also affects the
hash since different architectures may have different outputs.
- **Nixpkgs revision**: The exact version or revision of the nixpkgs repository
(or any other repository) used in the build also influences the hash.

## Note

- **nix-build vs nix build**:
  - `nix-build` is the older command used to build Nix expressions directly
  from files.
  - `nix build` is a newer command that is more compatible with flakes and newer
  Nix features. It's recommended to use `nix build` if you're working with flakes
  or modern Nix expressions, as it integrates better with the new ecosystem.

## Let's Play with Our Derivation

---

Here's an example of a simple derivation that compiles a C program:

```nix
# hello.c
{ pkgs ? import <nixpkgs> { } }:
pkgs.stdenv.mkDerivation {
  name = "hello";
  src = ./src;
  # TODO why don't I have to import GCC here?
  buildPhase = ''
    gcc $src/hello.c -o ./hello
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp ./hello $out/bin
  '';
}
```

---

## What are `$src` and `$out`?

- **`$src`**: This variable refers to the source code directory specified by the `src` attribute.
 In this example, it's the `./src` directory.
- **`$out`**: This variable represents the output directory in the Nix store where
the build results will be placed. Nix automatically sets this variable to a unique
path in the `/nix/store`.

---

If the derivation depends on other derivations, these are built first.

---

## Building the Derivation (from nixpkgs)

Nixpkgs is a vast repository that contains derivations for most of the software packages
 you might need. It's the primary package collection used by Nix and NixOS, offering a wide
variety of software from simple utilities to complex applications.
Each package in nixpkgs is represented by a derivation, which defines how the package
is built and configured.

---

For example, the Umoria package in nixpkgs can be examined and built with the following commands:

```bash
nix derivation show nixpkgs#sl
nix build nixpkgs#sl -L --rebuild
```

# Nix Store

![Nix Store](./pics/store.webp)

## Nix Store

The Nix store is a crucial component of the Nix package manager. Its primary purpose is to store
both the derivation files (`.drv`) and their output artifacts.
These outputs are stored in a deterministic manner, meaning that the same input
will always produce the same output path.

- **Location**: The Nix store is located at `/nix/store`.
- **Immutability**: Once a derivation is built and stored in the Nix store, it never changes.
- **Accessibility**: The store is readable by all users, allowing for shared access.

# Caches (TODO)

Caches (or **substituters**) play a vital role in speeding up the build process in Nix. Before Nix
builds a derivation, it checks the cache to see if the output already exists. If it does, Nix can
download the output directly from the cache instead of rebuilding it.

---

![Caches are Fast](./pics/caches-are-fast.png)

# NixOS

What if the entire operating system was the output of a derivation?
This is the idea behind NixOS, where everything from the kernel to user applications is managed
by Nix, ensuring that the system is fully reproducible and easily configurable.

# TODO: Flakes

![Flakes](./pics/fleyks.png)

## What Are Flakes?

Flakes are an experimental feature in Nix that introduces a more structured and reliable way to
manage Nix projects. They enforce purity by restricting access to paths outside the Nix store,
making builds more reproducible. Flakes provide a standard way to declare dependencies and interact
with them, and they are expected to become the standard in future versions of Nix.

## Simplest Possible Flake

Let's build the simplest possible flake:

```nix
{
  description = "A simple example flake";

  # Defines the checks run by `nix flake check`
  checks = {
    default = {
      # A dummy check that always passes
      inherit self;
    };
  };

  # Defines the packages that can be built with `nix build .#default`
  packages = {
    default = derivation {
      name = "example";
      builder = "bash";
      args = [ "-c" "echo Hello, World!" ];
    };
  };
}
```

## More Elaborate Flake Example

Here’s a more elaborate flake example with comments:

```nix
{
  description = "An advanced example flake";

  # Dependencies and inputs for the flake
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs, ... }:
  {
    # Checks that are run with `nix flake check`
    checks.x86_64-linux.hello = nixpkgs.lib.mkDerivation {
      pname = "hello";
      version = "2.10";
      src = self;
      buildInputs = [ nixpkgs.hello ];
    };

    # A package that can be built with `nix build .#hello`
    packages.x86_64-linux.hello = nixpkgs.lib.mkDerivation {
      pname = "hello";
      version = "2.10";
      src = self;
      buildInputs = [ nixpkgs.hello ];
    };

    # An app that can be run with `nix run .#hello`
    apps.x86_64-linux.hello = {
      type = "app";
      program = "${self.packages.x86_64-linux.hello}/bin/hello";
    };
  };
}
```

In this example:

- **Inputs**: The `inputs` section specifies external dependencies, like nixpkgs.
- **Outputs**: The `outputs` section defines checks, packages, and apps that are part of the flake.
 These are built and run using the corresponding Nix commands.

# TODO Use cases

## Dev Shells

>- **Easier Onboarding**: New developers quickly get up and running with a nix-shell that configures
all tools and dependencies automatically, eliminating setup hassles.
>- **Consistent Environment**: Ensures all team members use the same development environment,
preventing discrepancies and conflicts.

## Reproducible Builds

>- **Consistent Builds**: Guarantees that builds are identical across different machines,
eliminating “it works on my machine” issues.
>- **Stable CI Pipelines**: CI systems benefit from reproducible builds as they ensure that builds
are consistent and reliable, leading to more accurate testing and integration results.
>- **Efficient Caching**: Reproducible builds enable the use of caching mechanisms to speed up
development.
