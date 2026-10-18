{ pkgs, ... }:

{
  packages = [ pkgs.git ];

  languages.rust = {
    enable = true;
    channel = "nightly";
    # rust-src is needed for -Zbuild-std (no prebuilt std for the Wii target)
    components = [ "rustc" "cargo" "clippy" "rustfmt" "rust-analyzer" "rust-src" ];
  };
}
