use std::env;
use std::path::PathBuf;

fn main() {
    let mut manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    manifest_dir.push("star.map");
    println!("cargo:rustc-link-arg-bins=-Map={}", manifest_dir.display());
}
