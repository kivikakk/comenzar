{
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      ruby = pkgs.ruby;
    in {
      formatter = pkgs.alejandra;

      devShells.default = let
        env = pkgs.bundlerEnv {
          name = "comenzar-bundler-env";
          inherit ruby;
          gemfile = ./Gemfile;
          lockfile = ./Gemfile.lock;
          gemset = import ./gemset.nix;
        };
      in
        pkgs.mkShell {
          name = "comenzar";
          buildInputs = [
            ruby
            env
          ];
        };
    });
}
