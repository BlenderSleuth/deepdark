#![no_std]

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    loop {}
}

pub fn add(left: u64, right: u64) -> u64 {
    left + right
}
