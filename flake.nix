{
  description = "flake for one shell history";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";
    flake-utils.url = "github:numtide/flake-utils";
    mach-nix.url = "github:DavHau/mach-nix";

    osh = {
      # TODO update to latest main
      url = "git+ssh://git@github.com/dkuettel/one-shell-history?rev=1385eaec85ac774ad5381ef2e6cff4091276b828";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, osh, flake-utils, mach-nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        machNix = import mach-nix {
          inherit pkgs;
          python = "python39";
        };

        oshPythonDependencies = machNix.mkPython {
          # TODO: requirements = builtins.readFile ./python/requirements.txt;

          requirements = ''
            setuptools
            black ~= 21.8b0
            click ~= 8.0.1
            gitpython ~= 3.1.18
            ipython ~= 7.27.0
            isort ~= 5.9.3
            pyyaml ~= 6.0
            tabulate ~= 0.8.9
            tuna ~= 0.5.9
          '';

          providers = {
            _default = "wheel";
          };
        };

        one-shell-history = pkgs.stdenv.mkDerivation {
          name = "one-shell-history";
          version = "latest";
          src = osh;

          buildInputs = [ oshPythonDependencies pkgs.makeWrapper ];
          buildPhase = ''
            PYTHONPATH=python python3.9 -m osh
          '';

          installPhase = ''
            mkdir $out
            cp -r * $out/

            # patch bin/osh to use our Python
            echo "PYTHONPATH=$out/python python3.9 -m osh \$@" > $out/bin/osh
            wrapProgram $out/bin/osh --prefix PATH : ${oshPythonDependencies}/bin \

            # TODO systemd
          '';
        };

      in
      {
        packages = {
          default = one-shell-history;
          osh = one-shell-history;
        };
      }
    );
}
