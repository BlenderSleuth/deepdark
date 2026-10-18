{ pkgs, ... }:

{
  packages = [
    pkgs.git
    pkgs.cargo-binutils
  ];

  languages.rust = {
    enable = true;
    channel = "nightly";
    components = [ "rustc" "cargo" "clippy" "rustfmt" "rust-analyzer" "rust-src" "llvm-tools" ];
  };
}
