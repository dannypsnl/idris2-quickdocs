# Idris2 Quickdocs

From https://git.sr.ht/~cypheon/idris2-quickdocs, build for latest idris2

View on https://dannypsnl.github.io/idris2-quickdocs/

This is an index generator and fast documentation browser for
[Idris2](https://github.com/idris-lang/Idris2).


## Requirements

To generate the documentation index, you need Python 3,
[poetry](https://python-poetry.org/) and a recent (>= 0.5.1) version of Idris 2.

## Usage

Updating and serving the docs is a bit rought for now, but all the pieces are
available.

Run `poetry install` to install dependencies, then you can run the following:

```sh
IDRIS2_EXECUTABLE=path/to/idris2 IDRIS2_SRC=path/to/idris2/source/code ./rebuild_all.sh
```

The you can serve the current directory (don't do this in production!):

```sh
python3 -mhttp.server 8001
```

And your docs will be served at http://127.0.0.1:8001/
