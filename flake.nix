{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/release-23.11;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      ruby = pkgs.ruby;

      env = pkgs.bundlerEnv {
        name = "comenzar-bundler-env";
        inherit ruby;
        gemfile = ./Gemfile;
        lockfile = ./Gemfile.lock;
        gemset = import ./gemset.nix;
      };
    in {
      formatter = pkgs.alejandra;

      packages.default = pkgs.stdenv.mkDerivation {
        pname = "comenzar";
        version = "0.0.1";

        src = ./.;

        nativeBuildInputs = [pkgs.makeWrapper];

        buildInputs = [env];

        # I'm sure there's a better way to get the GEM_PATH out here.
        # Right?
        installPhase = ''
          mkdir -p $out
          cp -r * $out/
          wrapProgram $out/bin/comenzar \
            --prefix PATH : ${pkgs.lib.makeBinPath [env]} \
            --prefix GEM_PATH : ${env}/lib/ruby/gems/3.1.0
        '';
      };

      devShells.default = pkgs.mkShell {
        name = "comenzar";
        buildInputs = [
          ruby
          env
        ];
      };

      darwinModules.default = {
        config,
        lib,
        pkgs,
        ...
      }: let
        cfg = config.services.comenzar;
        inherit (lib) mkIf mkEnableOption mkOption types;
      in {
        options.services.comenzar = {
          enable = mkEnableOption "Enable the comenzar service";

          package = mkOption {
            type = types.package;
            default = self.packages.${system}.default;
            description = "Package to use for comenzar (defaults to this flake's).";
          };

          logFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "The logfile to use for the comenzar service.";
          };
        };

        config = mkIf (cfg.enable) {
          launchd.user.agents.comenzar = {
            serviceConfig = {
              ProgramArguments = ["${cfg.package}/bin/comenzar"];
              KeepAlive = true;
              RunAtLoad = true;
              ProcessType = "Background";
              StandardOutPath = cfg.logFile;
              StandardErrorPath = cfg.logFile;
              EnvironmentVariables = {};
            };
          };
        };
      };
    });
}
