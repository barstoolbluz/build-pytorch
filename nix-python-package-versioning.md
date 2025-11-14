# How Nix Organizes Python Packages by Version

## Overview

Nix creates version-specific Python package sets (like `python313Packages.torch`, `python312Packages.torch`) from a single package definition through parameterization and functional programming techniques. This document explains the mechanism.

## The Flow: Single Definition → Multiple Versions

### 1. **Single Package Definition**

You write ONE package definition in `pkgs/development/python-modules/torch/default.nix`:

```nix
{ lib
, buildPythonPackage
, fetchPypi
, numpy
, ... other dependencies
}:

buildPythonPackage rec {
  pname = "torch";
  version = "2.1.0";

  src = fetchPypi {
    inherit pname version;
    # ...
  };

  propagatedBuildInputs = [ numpy ... ];
  # ...
}
```

Notice it's **version-agnostic** - it doesn't hardcode Python 3.13 or any specific version.

### 2. **Registration in python-packages.nix**

The package gets registered in `pkgs/top-level/python-packages.nix`:

```nix
{
  torch = callPackage ../development/python-modules/torch { };
}
```

This is just a simple mapping - still no Python version specified!

### 3. **Version-Specific Instantiation**

Here's where the magic happens in `pkgs/development/interpreters/python/python-packages-base.nix`:

- For **each Python interpreter** (python313, python312, python311, etc.), Nix creates a **separate scope**
- This scope provides a version-specific `buildPythonPackage` function that's bound to that interpreter
- When `callPackage` evaluates your package, it automatically passes the **correct version's** `buildPythonPackage`

So when you access:
- `python313Packages.torch` → Uses `buildPythonPackage` bound to Python 3.13 interpreter
- `python312Packages.torch` → Uses `buildPythonPackage` bound to Python 3.12 interpreter

### 4. **How Dependencies Work**

When you specify `propagatedBuildInputs = [ numpy ]`, Nix automatically pulls `numpy` from the **same version's package set**. So:
- `python313Packages.torch` depends on `python313Packages.numpy`
- `python312Packages.torch` depends on `python312Packages.numpy`

This happens automatically through lexical scoping - the `self` parameter in `python-packages.nix` refers to the current version's package set.

## Key Components

### python-packages.nix
Located at `pkgs/top-level/python-packages.nix`, this file:
- Contains an alphabetically-sorted attribute set of all Python packages
- Uses `callPackage` to reference package definitions
- Provides the single source of truth for available Python packages

Example structure:
```nix
self: super: with self; {
  torch = callPackage ../development/python-modules/torch { };
  numpy = callPackage ../development/python-modules/numpy { };
  # ... thousands more packages
}
```

### python-packages-base.nix
Located at `pkgs/development/interpreters/python/python-packages-base.nix`, this file:
- Defines the core functions: `buildPythonPackage`, `buildPythonApplication`, etc.
- Exports version predicates: `isPy313`, `isPy312`, etc.
- Sets up the `namePrefix` (e.g., "python3.13-") for each version
- Enables `.override` and `.overrideAttrs` functionality

### buildPythonPackage
Implemented in `pkgs/development/interpreters/python/mk-python-derivation.nix`:
- The primary function for building Python packages
- Automatically bound to a specific Python interpreter
- Handles dependency resolution within the same Python version
- Adds proper naming conventions (e.g., "python3.13-torch")

## In Summary

You **don't** manually create separate packages for each Python version. Instead:

1. Write ONE package definition using `buildPythonPackage`
2. Register it in `python-packages.nix` with `callPackage`
3. Nix automatically instantiates it for ALL Python versions through parameterization
4. Each version gets its own isolated dependency graph

The "umbrella category" you see (`python313Packages.*`) is really just a namespace - a scope where all functions and dependencies are bound to Python 3.13. It's beautiful functional programming at work!

## Practical Implications

### For Package Authors
- Write your package once in `pkgs/development/python-modules/<name>/default.nix`
- Use `buildPythonPackage` and declare dependencies normally
- The package automatically works with all supported Python versions

### For Package Users
- Access packages through version-specific sets: `python313Packages.torch`
- Dependencies are automatically version-consistent
- Can override packages per-version using `.override` or overlays

### For Custom Packages
When creating custom Python packages (e.g., in Flox or local overlays):
- Follow the same pattern: use `buildPythonPackage` from the desired Python version
- The package will automatically integrate with that version's ecosystem
- Dependencies will be resolved from the same version's package set

## References

- [NixOS/nixpkgs Python Documentation](https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/python.section.md)
- [python-packages.nix](https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/python-packages.nix)
- [python-packages-base.nix](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/interpreters/python/python-packages-base.nix)
