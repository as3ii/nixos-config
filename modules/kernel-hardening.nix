# Based on https://kspp.github.io/Recommended_Settings#kernel-command-line-options
{ lib, ... }:

{
  # Harden sysctl
  boot.kernel.sysctl = {
    # Note: Other settings are already set by default like:
    #kernel.kptr_restrict = 1
    #kernel.dmesg_restrict = 1
    #kernel.perf_event_paranoid = 2
    #dev.tty.ldisc_autoload = 0
    #fs.protected_hardlinks = 1
    #fs.protected_symlinks = 1
    #fs.protected_regular = 1
    #fs.protected_fifos = 1
    # and other network-related settings

    # eBPF hardening
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;

    # Disable kexec
    "kernel.kexec_load_disabled" = 1;

    # Increase entropy for ASLR
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_rnd_compat_bits" = 16;
  };

  boot.kernelParams = [
    # Randomize kernel stack offset on each syscall
    "randomize_kstack_offset=1"
    # Randomize page allocator
    "page_alloc.shuffle=1"
    # Always enable mitigations for Meltdown
    #"pti" = 1
  ] ++ lib.optional (builtins.currentSystem == "x86_64-linux") [
    "vsyscall=none"
  ];
}
