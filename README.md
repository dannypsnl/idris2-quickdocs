# Idris2 Quickdocs

This is an index generator and fast documentation browser for
[Idris2](https://github.com/idris-lang/Idris2).

## Live Demo

A demo of this is hosted at [https://idris2docs.sinyax.net](https://idris2docs.sinyax.net)

## Requirements

To generate the documentation index, you need Python 3,
[poetry](https://python-poetry.org/) and the [`mkdoc` branch of my Idris2
fork](https://github.com/cypheon/Idris2/tree/mkdoc) (at least until the doc
generation is ready to be upstreamed).

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