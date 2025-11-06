# Based on https://kspp.github.io/Recommended_Settings#kernel-command-line-options
{ lib, pkgs, ... }:

{
  # Harden sysctl
  boot.kernel.sysctl = {
    # Note: Other settings are already set by default like:
    #kernel.kptr_restrict = 1
    #kernel.dmesg_restrict = 1
    #kernel.perf_event_paranoid = 2
    "dev.tty.ldisc_autoload" = 0; # Restrict loading of TTY line discilines
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

    # Disable memory dump of suid processes
    "fs.suid_dumpable" = 0;
  };

  boot.kernelParams = [
    # Randomize kernel stack offset on each syscall
    "randomize_kstack_offset=1"
    # Randomize page allocator
    "page_alloc.shuffle=1"
    # Always enable mitigations for Meltdown
    #"pti" = 1
  ] ++ lib.optionals (pkgs.system == "x86_64-linux") [
    "vsyscall=none"
  ];

  boot.blacklistedKernelModules = [
    # Old/rare network protocols
    "appletalk" # AppleTalk
    "ax25" # Amateur X.25
    "dccp" # Datagram Congestion Control Protocol
    "n-hdlc" # High-level Data Link Control
    "netrom" # Amateur radio protocol ontop ax25
    "rds" # Reliable Datagram Sockets
    "rose" # Amateur radio protocol ontop ax25
    "sctp" # Stream Control Transmission Protocol
    "tipc" # Transparent Inter Process Communication / Cluster Domain Sockets
    "x25" # X.25

    # Old/rare/insufficiently audited filesystems
    "adfs" # Acorn Disc Filing System
    "affs" # Amiga Fast File System
    "bfs" # SCO UnixWare BFS filesystem
    "befs" # BeOS File System
    "cramfs" # Compressed ROM file system
    "efs" # Extent File System
    "erofs" # Enhanced ROM File System
    "exofs" # EXtended Object File System (was osdfs)
    "freevxfs" # Veritas Filesystem
    "hfs" # Apple Macintosh file system
    "hpfs" # OS/2 HPFS file system
    "jfs" # The Journaled Filesystem
    "minix" # Minix file system
    "nilfs2" # A New Implementation of the Log-structured Filesystem
    "omfs" # Optimized MPEG Filesystem
    "qnx4" # QNX4 FS
    "qnx6" # QNX6 FS
    "sysv" # SystemV Filesystem
    "ufs" # Unix File System
  ];
}
