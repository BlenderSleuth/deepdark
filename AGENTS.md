# deepdark: session initialisation prompt

I'm starting **deepdark**: a bare-metal runtime for the Nintendo Wii, written in Rust and PowerPC assembly. I'm writing it independently from public hardware documentation. It's a learning exercise to understand embedded systems and very low-level code, not something I plan to release. Please read all of this before helping.

## Ground rules (clean-room style)

The aim is that all of the implementation is my own work, based on hardware documentation. I'm not aiming to reproduce or adapt existing Wii libraries.

1. **Do not fetch, open, search or quote source code from:**
   - libogc, libogc2, devkitPro's tuxedo/calico, or anything derived from them (including ogc-rs's bindings and glue)
   - BootMii's `mini`, the Linux kernel's Wii/GameCube drivers, Dolphin's source code
   - leaked or decompiled Nintendo SDK code

   This applies to web searches, GitHub and tool calls too. If a search result points into one of these, don't open it.
2. **Allowed sources** (prefer these, and cite them):
   - WiiBrew wiki: hardware registers, IOS, IPC, DOL format, Homebrew Channel conventions
   - YAGCD (*Yet Another GameCube Documentation*): Flipper/Hollywood hardware shared with the GameCube
   - IBM *PowerPC 750CL RISC Microprocessor User's Manual* (Broadway is a 750CL derivative)
   - IBM *Programming Environments Manual for 32-bit Implementations of the PowerPC Architecture*
   - The PowerPC EABI / SVR4 ABI specifications
   - Rust, LLVM and lld documentation
   - Observing behaviour in Dolphin as a black box (logs, debugger, memory viewer, FIFO player) and on my real Wii
3. **Cite where hardware facts come from** (document and section/page) so I can check them. Say so plainly when you're working from memory and can't point to a source. You may have seen libogc in training, so be wary of reproducing its structure, naming (e.g. `__lwp_*`, `VIDEO_*`, `_CPU_ISR_*`), module layout or code idioms. Register addresses, bit layouts and protocols are facts and fine to use. Code structure and expression must be mine.
4. **I write the code.** Your role is to explain, plan, point me to documentation, review my code and help debug. Small illustrative snippets in chat are fine when I ask. Don't write implementation code into `src/` unless I explicitly ask in that instance. Toolchain and config changes: ask first.
5. I'll describe the result as "independently implemented from public hardware documentation, with AI assistance", not as strictly clean-room.

## Environment

- **Host:** Windows 11 running **NixOS in WSL2** (distro `NixOS`, user `nixos`). There is no devkitPro anywhere in this setup, by design.
- **Project:** `~/deepdark` (`\\wsl.localhost\NixOS\home\nixos\deepdark`). It's a git repo on branch `main` with an initial commit. Commits are signed with SSH through 1Password (`op-ssh-sign-wsl.exe`), and that works.
- **devenv 2.4** manages dependencies. `devenv.yaml` has inputs `nixpkgs` (cachix/devenv-nixpkgs rolling) and `rust-overlay` (follows nixpkgs). `devenv.nix` enables `languages.rust` on the `nightly` channel with components rustc, cargo, clippy, rustfmt, rust-analyzer and **rust-src** (needed for `-Zbuild-std`).
- **direnv** is enabled system-wide, and the project has a `.envrc` (`eval "$(devenv direnvrc)"` / `use devenv`). Non-interactively, run commands with `direnv exec ~/deepdark <cmd>` or `devenv shell -- <cmd>`.
- **System config** (`/etc/nixos/configuration.nix`): experimental features `nix-command` and `flakes` are on, devenv and git are system packages, and `programs.direnv.enable = true`. `nixos-rebuild switch` exits non-zero because a WSL-generated `wsl-mnt-guard.service` points at `/bin/true`. That's harmless.
- **Tooling gotchas when driving WSL from PowerShell:**
  - Piping text into `wsl` adds CRLF line endings, so strip them with `sed -i 's/\r$//'`.
  - `wsl -- bash -lc '...'` expands `$vars` and `$(...)` before bash sees them. For anything non-trivial, write a script to `\\wsl.localhost\NixOS\tmp\` (LF endings) and run it.
- **Testing:** Dolphin (Windows build) and a real Wii with the Homebrew Channel. Deployment tools such as `wiiload` and `elf2dol` are not installed. I'll write or choose my own.

## Technical plan

The output is a DOL that the Homebrew Channel can launch, built with nothing from devkitPro:

- `#![no_std]`, `#![no_main]`
- A custom target JSON: big-endian 32-bit PowerPC, `cpu: 750`, hard-float, EABI. Rust has no built-in Wii target.
- `-Zbuild-std=core,alloc`, linked with `rust-lld` and my own linker script
- My own ELF→DOL converter. A DOL has up to 7 text and 11 data sections, plus the BSS range and an entry point.

LLVM doesn't generate Broadway's paired-single instructions, so use inline asm if I ever need them.

Milestones, roughly in order of difficulty:

0. **Toolchain:** target JSON, linker script, build-std, ELF→DOL tool, loading in Dolphin.
1. **`_start` in assembly:**
   - disable interrupts
   - set up the memory map with BAT registers (MEM1 cached and uncached mirrors, MEM2, the hardware register area)
   - configure the CPU's HID registers (caches, paired singles, Wii-specific HID4 bits)
   - set the stack pointer (`r1`) and the small-data base registers (`r2`/`r13`)
   - enable the FPU, clear `.bss`, jump to Rust

   Low memory holds OS globals left by the previous loader, so check WiiBrew for what's there.
2. **Pixels on screen:** program the video interface (VI) registers, write to the external framebuffer (XFB, YUV422), then a bitmap font and `println!`.
3. **Exceptions and interrupts:**
   - exception vector stubs and saving/restoring context
   - the decrementer (timer interrupt)
   - the processor interface (PI) and Hollywood interrupt controllers
   - vertical-blank sync, a panic screen, and a heap allocator
4. **GameCube controller input** through the serial interface (SI). This is the simplest input path.
5. **IOS IPC** with Starlet (open/ioctl/ioctlv, cache flush/invalidate around shared buffers). It unlocks the SD card, NAND filesystem, system settings, and return-to-loader.
6. **GX:** the command FIFO through the write-gather pipe, BP/CP/XF registers, vertex formats, TEV, texture formats. This is the largest gap in the documentation, so expect to fill it by testing in Dolphin and on hardware rather than reading emulator source.
7. **Audio:** mix on the CPU and stream PCM through the audio interface (AI) DMA. Writing my own DSP microcode is a stretch goal.
8. **Wii Remote:** Bluetooth through IOS (HCI, L2CAP, pairing) and the Wii Remote's HID protocol. This is the biggest milestone.

Milestones 1–4 are the realistic first goal. Treat every register address and bit layout as "verify against the docs", not as given.

## How to start

Begin with milestone 0. Help me understand what the target JSON, linker script and DOL format need to contain, point me to the relevant documentation, and let me write them.
