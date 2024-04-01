## This file is part of UovoEnergy.

## UovoEnergy is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

## UovoEnergy is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

## You should have received a copy of the GNU General Public License along with UovoEnergy. If not, see <https://www.gnu.org/licenses/>.

{
  # Flake inspired by this Fernando Ayats' post:
  # https://ayats.org/blog/no-flake-utils/
  
  description = "Uovo Energy - Connect to My Ovo Energy, retrieve your data and plot it";

  outputs = {self, nixpkgs}:
    let

      forAllSystems = function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
          "aarch64-linux"
        ] (system: function nixpkgs.legacyPackages.${system});

      getRPackages = pkgs: with pkgs.rPackages; [
          tidyverse
          tibbletime
          jsonlite
          maybe
          proceduralnames
          # httr2 version is too old. We need a newer version.
          (httr2.override {
            version="1.0.0";
            sha256="sha256-y4Utb1YMMpp9wXqnYPCaCVBBNRPcir/D+stkGLKTSkk=";
            # lifecycle and vctrs are the new version's dependecies
            depends=[cli curl glue magrittr openssl R6 rappdirs rlang withr lifecycle vctrs];
          })
          shiny
        ]; # getRPackages

      # Function that receives a pkgs argument and return the list of R packages needed 
      getREnv = pkgs: pkgs.rWrapper.override {
        packages = (getRPackages pkgs) ++ [ pkgs.rPackages.devtools ];
      }; # getREnv

      getUovoPkg = pkgs: pkgs.rPackages.buildRPackage {
        name = "UovoEnergy";
        version = "v0.1";
        src = ./.;
        propagatedBuildInputs = (getRPackages pkgs);
      }; #UovoEnergy package

    in { #output's let

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [ (getREnv pkgs) ]
                                ++ lib.optionals stdenv.isLinux [ xdg-utils ];
          shellHook = with pkgs; lib.optionalString stdenv.isLinux "export R_BROWSER=${xdg-utils}/bin/xdg-open"
                                 + lib.optionalString stdenv.isDarwin "export R_BROWSER=open";
        };
      }); # devShells

      # "nix run" to run the server
      apps = forAllSystems (pkgs: {
        default = let
          app_uovo = (getUovoPkg pkgs);
          app_rpkgs = (getRPackages pkgs) ++ [ app_uovo ];
          app_renv = (pkgs.rWrapper.override {
            packages = app_rpkgs;
          });
          server = pkgs.writeShellApplication {
            name = "runUovoEnergyServer";
            runtimeInputs = [ app_renv ];
            text = "Rscript --vanilla -e 'UovoEnergy::launch()'";
          };
        in
          {
            type = "app";
            program = "${server}/bin/runUovoEnergyServer";
          };
      }); # apps

      packages = forAllSystems (pkgs: {
        default = (getUovoPkg pkgs);

        # Define a docker image
        # build: nix build .#docker
        # run: docker run -itp 3000:8000 uovoenergy:v0.1
        docker = pkgs.dockerTools.buildLayeredImage {
          name = "UovoEnergy";
          tag = "v0.1";
          contents = [
            (pkgs.rWrapper.override {
              packages = [ (getRPackages pkgs)
                           (getUovoPkg pkgs) ];
            })
            pkgs.coreutils
            pkgs.bash ];
          config = {
            #              Cmd = [ "Rscript --vanilla -e 'UovoEnergy::launch()'" ];
              WorkingDir = "/";
              Env = [ "TMPDIR=/dev/shm" ];
          };
        }; # docker
        
      }); # packages
      
    }; #output's in

} # flake end
