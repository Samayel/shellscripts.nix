{

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-22.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    devshell.inputs.flake-utils.follows = "flake-utils";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    qnixpkgs.url = "github:Samayel/qnixpkgs";
    qnixpkgs.inputs.nixpkgs.follows = "nixpkgs";
    qnixpkgs.inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
    qnixpkgs.inputs.flake-utils.follows = "flake-utils";
    qnixpkgs.inputs.devshell.follows = "devshell";
    qnixpkgs.inputs.flake-compat.follows = "flake-compat";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, devshell, qnixpkgs, ... }:
    let
      version = builtins.substring 0 8 self.lastModifiedDate;
    in
    {
      overlays = {
        default = import ./overlay.nix version;
      };
    }
    //
    flake-utils.lib.eachSystem [ flake-utils.lib.system.x86_64-linux ] (system:
      let

        flakeOverlays = (builtins.attrValues self.overlays) ++ [
          devshell.overlay
          qnixpkgs.overlays.qshell
        ];

        # can now use "pkgs.package" or "pkgs.unstable.package"
        unstableOverlay = final: prev: {
          unstable = import nixpkgs-unstable {
            inherit system;
            overlays = flakeOverlays;
          };
        };

        pkgs = import nixpkgs {
          inherit system;
          overlays = [ unstableOverlay ] ++ flakeOverlays;
        };

        flakePkgs = {
          inherit (pkgs)
            cachixsh
            nixbuildsh
            nixsh;
        };

      in {

        packages = flakePkgs
          //
          {
            default = pkgs.linkFarmFromDrvs "shellscripts-packages-all" (map (x: flakePkgs.${x}) (builtins.attrNames flakePkgs));

            ci-build = self.packages.${system}.default;
            ci-publish = self.packages.${system}.default;

            docker = import ./docker.nix pkgs;
          };

        apps = import ./apps.nix pkgs;

        devShells = {
          default = with pkgs.devshell; mkShell {
            imports = [ (importTOML ./devshell.toml) ];
          };
        };

      }
    );

}
