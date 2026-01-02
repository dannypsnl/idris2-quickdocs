# Idris2 Quickdocs

From https://git.sr.ht/~cypheon/idris2-quickdocs, build for latest idris2

View on https://dannypsnl.github.io/idris2-quickdocs/

This is an index generator and fast documentation browser for
[Idris2](https://github.com/idris-lang/Idris2).


## Requirements

To generate the documentation index, you need Python 3,
[uv](https://docs.astral.sh/uv/) and a recent (>= 0.5.1) version of Idris 2.

## Usage

### `rebuild_all.sh`

This script rebuilds the documentation for the built in packages.

Run `uv pip install` to install dependencies, then you can run the following:

```sh
IDRIS2_EXECUTABLE=path/to/idris2 IDRIS2_SRC=path/to/idris2/source/code ./rebuild_all.sh
```

The you can serve the current directory (don't do this in production!):

```sh
python3 -mhttp.server 8001
```

And your docs will be served at http://127.0.0.1:8001/

### `pack-mkquickdocs.sh`

This script uses pack to check for dependencies in the current working directory, builds their documentation, and serves them using python.

Use it like:

```sh
pack-mkquickdocs.sh
```

while the script is in your PATH, and you're in a directory containing a package's `.ipkg` file.

### Flake

This repository as of recently exposes a Nix flake with the following outputs:

#### `devShells.<system>.default`
The development shell for developing idris2-quickdocs itself.
Uses uv2nix internally.

#### `packages.<system>.default`
Package for idris2-quickdocs, containing the scripts as defined in the `pyproject.toml` in the `/bin` output folder.

#### `quickdocs.<system>`
Nix function which builds several package's documentation and outputs a package with a script to serve said documentation.

It takes a single attribute set as input with the following attributes:

```
name
    The name for the internal virtualenv. Should be set to something appropriate for the package you're developing.
deps
    The idris2 dependencies for your project.
    Should be an array of pacakages built with buildIdris, preferably.
    Should not include the built-in libraries (base, prelude, contrib, test, etc)
    Contrary to what the name implies, can also include the package you're working on, though
    be aware the derivation will fail if your project's package doesn't yet build.
builtinPackages
    Should be an array of the names of the built-in libraries to include in the output.
    This attribute is optional, and defaults to [ "base" "prelude" ]  
```

It outputs a package, exposing a single executable script in the `/bin` output folder, `serve-quickdocs`.
This script serves the built documentation when run, using python's built in http server. 
This script's help output is shown below:

```
Usage: serve-quickdocs [<port> | dir | help | --help | -h]
---
help | -h | --help: Prints this help message 
dir: Prints the directory where the built documentation is located 
<port>: Specifies the port the server will serve the documentation at
--- 
If the argument is not specified, will host the documentation at port 8080
```
