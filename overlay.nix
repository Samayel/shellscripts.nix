version: final: prev:

let

  mkShellscriptDerivation = with prev; src: extraBuildInputs: patchPhase:
    stdenv.mkDerivation {
      pname = baseNameOf src;
      inherit version;
      inherit src;
      buildInputs = [ bash ] ++ extraBuildInputs;
      inherit patchPhase;
      installPhase = "mkdir -p $out/bin && cp * $out/bin/";
    };

in with prev; {

  nixsh = mkShellscriptDerivation ./nix.sh [] "";

  cachixsh = mkShellscriptDerivation ./cachix.sh [ cachix jq ] ''
    sed -i -e "s|cachix |${cachix}/bin/cachix |g" cachix-*
    sed -i -e "s|jq |${jq}/bin/jq |g"             cachix-*
  '';

  nixbuildsh = mkShellscriptDerivation ./nixbuild.sh [ rlwrap ] ''
    sed -i -e "s|rlwrap |${rlwrap}/bin/rlwrap |g" nixbuild-*
  '';

}
