#if !defined (jailbreak_protect) && defined (__arm64__)
#define jailbreak_protect
#define IS_APP_STORE_BUILD !TARGET_IPHONE_SIMULATOR && !DEBUG

#if IS_APP_STORE_BUILD
#define prevent_debugger PfdVSCqqteGFWxmSPFAw // Obfuscate function name

/**
 Prevent debugger attachment by invoking underlying syscalls ptrace uses.

 Most anti-debug code relies on libraries which are easy enough to hook
 the symbols and bypass these checks. This is an ARM64 assembly solution
 which requires much more effort to bypass.

 This code is executed by dyld (the dynamic linker) during the initialization phase,
 before the instruction pointer enters the program code.
 */
__attribute__((constructor)) static void prevent_debugger() {
    asm volatile (
        "mov x0, #26\n" // ptrace syscall (26 in XNU)
        "mov x1, #31\n" // PT_DENY_ATTACH (0x1f) - first arg
        "mov x2, #0\n"
        "mov x3, #0\n"
        "mov x16, #0\n"
        "svc #128\n"    // make syscall
    );
}

#endif
#endif /* jailbreak_protect */
