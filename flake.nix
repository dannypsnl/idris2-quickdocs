{
  description = "Idris2-Quickdocs, A searchable idris2 documentation generator";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;

      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

      overlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };

      editableOverlay = workspace.mkEditablePyprojectOverlay {
        root = "$REPO_ROOT";
      };

      pythonSets = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          python = pkgs.python3;
        in
        (pkgs.callPackage pyproject-nix.build.packages {
          inherit python;
        }).overrideScope
          (
            lib.composeManyExtensions [
              pyproject-build-systems.overlays.wheel
              overlay
            ]
          )
      );

    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pythonSet = pythonSets.${system}.overrideScope editableOverlay;
          virtualenv = pythonSet.mkVirtualEnv "idris2-quickdocs-env" workspace.deps.all;
        in
        {
          default = pkgs.mkShell {
            packages = [
              virtualenv
              pkgs.uv
            ];
            env = {
              UV_NO_SYNC = "1";
              UV_PYTHON = pythonSet.python.interpreter;
              UV_PYTHON_DOWNLOADS = "never";
            };
            shellHook = ''
              unset PYTHONPATH
              export REPO_ROOT=$(git rev-parse --show-toplevel)
            '';
          };
        }
      );

      packages = forAllSystems (system: {
        default = pythonSets.${system}.mkVirtualEnv "idris2-quickdocs-env" workspace.deps.default; 
      });

      quickdocs = forAllSystems (system: {name, deps, builtinPackages ? [ "base" "prelude" ] }:
        let 
          pkgs = import nixpkgs { inherit system; };
          builtinPackageDocs = name: (
              pkgs.idris2.unwrapped.overrideAttrs (old: {
                inherit name;
                nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.idris2 ];
                phases = [ "unpackPhase" "configurePhase" "patchPhase" "buildPhase" "installPhase" ];
                outputs = [ "out" ];
                checkPhase = "";
                buildPhase =
                  ''
                  cd libs/${name};
                  idris2 --mkdoc '${name}.ipkg';
                  '';
                installPhase =
                  ''
                  mkdir -p "$out";
                  cp -r "build/docs/"* "$out";
                  '';
              }
            )
          );
          withDocs = dep:
            (dep.overrideAttrs {
              phases = [ "unpackPhase" "patchPhase" "buildPhase" "installPhase" ];
              outputs = [ "out" ];
              buildPhase = 
                ''
                printf "%s\n" *.ipkg | xargs -I{} idris2 --mkdoc {};
                '';
              installPhase =
                ''
                mkdir -p "$out";
                cp -r "build/docs/"* "$out";
                '';
            });
          deps' = (builtins.map builtinPackageDocs builtinPackages) ++ (builtins.map withDocs deps); 
          depsDocs = builtins.map (x: "'${x.name}' '${x.out}'") deps';
          depsDocs' = builtins.concatStringsSep " " depsDocs;
          builtDocs = (
            pkgs.stdenv.mkDerivation {
              inherit name;
              outputHashMode = "recursive";
              outputHashAlgo = "sha256";
              builder = pkgs.writeScript "builder.sh" ''
                export PATH=$PATH:${pythonSets.${system}.mkVirtualEnv "idris2-quickdocs-${name}-serve-env" workspace.deps.default}/bin;
                ${./build_quickdocs_nix.sh} $out ${depsDocs'};
              '';
            }
          );
        in
          pkgs.writeScriptBin "serve-quickdocs"
            ''
            case $1 in
              "help" | "-h" | "--help" )
                printf "%s\n" \
                  "Usage: serve-quickdocs [<port> | dir | help | --help | -h]"            \
                  "---"                                                                   \
                  "help | -h | --help: Prints this help message"                          \
                  "dir: Prints the directory where the built documentation is located"    \
                  "<port>: Specifies the port the server will serve the documentation at" \
                  "---"                                                                   \
                  "If the argument is not specified, will host the documentation at port 8080";
                exit;
                ;;
              "dir" )
                printf "%s\n" '${builtDocs}';
                exit;
                ;;
              * )
                cd ${builtDocs};
                ${pkgs.python3}/bin/python3 -m http.server "''${1:-8080}";
                ;;
            esac
            ''
      );
    };
}
