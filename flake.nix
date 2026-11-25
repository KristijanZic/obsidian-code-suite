{
  description = "CodeSuite — syntax highlighting and live code execution plugin for Obsidian";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      manifest = builtins.fromJSON (builtins.readFile ./manifest.json);
    in
    {
      packages = forAllSystems (
        pkgs:
        let
          obsidian-code-suite = pkgs.buildNpmPackage {
            pname = manifest.id;
            version = manifest.version;

            src = pkgs.lib.cleanSourceWith {
              src = self;
              filter =
                path: type:
                let
                  baseName = baseNameOf (toString path);
                in
                !(builtins.elem baseName [
                  "node_modules"
                  "dist"
                  "result"
                ]);
            };

            npmDepsHash = "sha256-iIAC3xQ53XMg3hMoahOuPYw2fWV8JrKS+w6tgMaXN70=";

            installPhase = ''
              runHook preInstall

              mkdir -p $out
              cp dist/main.js manifest.json styles.css $out/

              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = manifest.description;
              homepage = "https://github.com/felixleopold/obsidian-code-suite";
              license = licenses.asl20;
              platforms = platforms.all;
            };
          };
        in
        {
          default = obsidian-code-suite;
          inherit obsidian-code-suite;
        }
      );

      overlays.default = final: _prev: {
        obsidian-code-suite = self.packages.${final.stdenv.hostPlatform.system}.default;
      };

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.nodejs ];
        };
      });
    };
}
