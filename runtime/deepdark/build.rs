use std::env;

fn main() {
    println!("cargo::rustc-link-search={}", env::var("OUT_DIR").unwrap());
    println!("cargo::rerun-if-changed=link.ld");
}
