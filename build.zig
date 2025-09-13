const std = @import("std");
const builtin = @import("builtin");

const SourceFile = struct {
    name: []const u8,
    directory: []const u8,

    pub fn toLazyPath(self: SourceFile, b: *std.Build) std.mem.Allocator.Error!std.Build.LazyPath {
        var buf: std.ArrayList(u8) = .empty;
        try buf.appendSlice(b.allocator, self.directory);
        try buf.appendSlice(b.allocator, self.name);
        return b.path(buf.items);
    }

    pub fn toTmpFileName(self: SourceFile, b: *std.Build) std.mem.Allocator.Error![]const u8 {
        var buf: std.ArrayList(u8) = .empty;
        for (self.directory) |letter| {
            try buf.append(b.allocator, switch (letter) {
                '/' => '.',
                else => |other| other,
            });
        }
        try buf.appendSlice(b.allocator, self.name);
        try buf.appendSlice(b.allocator, ".json.tmp");
        return buf.items;
    }
};

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // ********************************************************************* //
    //                Replacements for configure script flags                //
    // ********************************************************************* //
    const with_sdl: bool = b.option(
        bool,
        "with-sdl",
        "Link against and make SDL available",
    ) orelse false;

    const with_x11: bool = b.option(
        bool,
        "with-x11",
        "Link against and make X11 available",
    ) orelse false;

    // ********************************************************************* //
    // *** Individual Modules (1:1 mapping to old Makefiles static libs) *** //
    // ********************************************************************* //

    const iodev_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    iodev_module.addIncludePath(b.path("bochs/generated/"));
    iodev_module.addIncludePath(b.path("bochs/"));
    iodev_module.addIncludePath(b.path("bochs/instrument/stubs/"));
    const iodev_module_files: []const SourceFile = comptime &.{
        .{ .directory = "bochs/iodev/", .name = "devices.cc" },
        .{ .directory = "bochs/iodev/", .name = "virt_timer.cc" },
        .{ .directory = "bochs/iodev/", .name = "slowdown_timer.cc" },
        .{ .directory = "bochs/iodev/", .name = "pic.cc" },
        .{ .directory = "bochs/iodev/", .name = "pit.cc" },
        .{ .directory = "bochs/iodev/", .name = "serial.cc" },
        .{ .directory = "bochs/iodev/", .name = "parallel.cc" },
        .{ .directory = "bochs/iodev/", .name = "floppy.cc" },
        .{ .directory = "bochs/iodev/", .name = "keyboard.cc" },
        .{ .directory = "bochs/iodev/", .name = "biosdev.cc" },
        .{ .directory = "bochs/iodev/", .name = "cmos.cc" },
        .{ .directory = "bochs/iodev/", .name = "harddrv.cc" },
        .{ .directory = "bochs/iodev/", .name = "dma.cc" },
        .{ .directory = "bochs/iodev/", .name = "unmapped.cc" },
        .{ .directory = "bochs/iodev/", .name = "extfpuirq.cc" },
        .{ .directory = "bochs/iodev/", .name = "speaker.cc" },
        .{ .directory = "bochs/iodev/", .name = "ioapic.cc" },
        .{ .directory = "bochs/iodev/", .name = "pci.cc" },
        .{ .directory = "bochs/iodev/", .name = "pci2isa.cc" },
        .{ .directory = "bochs/iodev/", .name = "pci_ide.cc" },
        .{ .directory = "bochs/iodev/", .name = "acpi.cc" },
        .{ .directory = "bochs/iodev/", .name = "hpet.cc" },
        .{ .directory = "bochs/iodev/", .name = "pit82c54.cc" },
        .{ .directory = "bochs/iodev/", .name = "scancodes.cc" },
        .{ .directory = "bochs/iodev/", .name = "serial_raw.cc" },
    };
    inline for (iodev_module_files) |file| {
        iodev_module.addCSourceFile(.{
            .file = file.toLazyPath(b) catch unreachable,
            .flags = &.{
                "-MJ",
                file.toTmpFileName(b) catch unreachable,
            },
            .language = .cpp,
        });
    }
    iodev_module.addCMacro("_FILE_OFFSET_BITS", "64");
    iodev_module.addCMacro("_LARGE_FILES", "");
    if (with_sdl) {
        iodev_module.addCMacro("_GNU_SOURCE", "1");
        iodev_module.addCMacro("_REENTRANT", "");
        iodev_module.linkSystemLibrary(
            "SDL",
            .{ .preferred_link_mode = .dynamic },
        );
    }

    const display_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    display_module.addIncludePath(b.path("bochs/generated/"));
    display_module.addIncludePath(b.path("bochs/iodev/"));
    display_module.addIncludePath(b.path("bochs/"));
    display_module.addIncludePath(b.path("bochs/instrument/stubs/"));
    const display_module_files: []const SourceFile = comptime &.{
        .{ .directory = "bochs/iodev/display/", .name = "vga.cc" },
        .{ .directory = "bochs/iodev/display/", .name = "vgacore.cc" },
        .{ .directory = "bochs/iodev/display/", .name = "ddc.cc" },
    };
    inline for (display_module_files) |file| {
        display_module.addCSourceFile(.{
            .file = file.toLazyPath(b) catch unreachable,
            .flags = &.{
                "-MJ",
                file.toTmpFileName(b) catch unreachable,
            },
            .language = .cpp,
        });
    }
    display_module.addCMacro("_FILE_OFFSET_BITS", "64");
    display_module.addCMacro("_LARGE_FILES", "");
    if (with_sdl) {
        display_module.addCMacro("_GNU_SOURCE", "1");
        display_module.addCMacro("_REENTRANT", "");
        display_module.linkSystemLibrary(
            "SDL",
            .{ .preferred_link_mode = .dynamic },
        );
    }

    const hdimage_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    hdimage_module.addIncludePath(b.path("bochs/generated/"));
    hdimage_module.addIncludePath(b.path("bochs/iodev/"));
    hdimage_module.addIncludePath(b.path("bochs/"));
    hdimage_module.addIncludePath(b.path("bochs/instrument/stubs/"));
    const hdimage_module_files: []const SourceFile = comptime &.{
        .{ .directory = "bochs/iodev/hdimage/", .name = "hdimage.cc" },
        .{ .directory = "bochs/iodev/hdimage/", .name = "cdrom.cc" },
        .{ .directory = "bochs/iodev/hdimage/", .name = "cdrom_misc.cc" },
        .{ .directory = "bochs/iodev/hdimage/", .name = "vbox.cc" },
        .{ .directory = "bochs/iodev/hdimage/", .name = "vmware3.cc" },
        .{ .directory = "bochs/iodev/hdimage/", .name = "vmware4.cc" },
        .{ .directory = "bochs/iodev/hdimage/", .name = "vpc.cc" },
        .{ .directory = "bochs/iodev/hdimage/", .name = "vvfat.cc" },
    };
    inline for (hdimage_module_files) |file| {
        hdimage_module.addCSourceFile(.{
            .file = file.toLazyPath(b) catch unreachable,
            .flags = &.{
                "-MJ",
                file.toTmpFileName(b) catch unreachable,
            },
            .language = .cpp,
        });
    }
    hdimage_module.addCMacro("_FILE_OFFSET_BITS", "64");
    hdimage_module.addCMacro("_LARGE_FILES", "");
    if (with_sdl) {
        hdimage_module.addCMacro("_GNU_SOURCE", "1");
        hdimage_module.addCMacro("_REENTRANT", "");
        hdimage_module.linkSystemLibrary(
            "SDL",
            .{ .preferred_link_mode = .dynamic },
        );
    }

    const cpu_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    cpu_module.addIncludePath(b.path("bochs/generated/"));
    cpu_module.addIncludePath(b.path("bochs/"));
    cpu_module.addIncludePath(b.path("bochs/instrument/stubs/"));
    const cpu_module_files: []const SourceFile = comptime &.{
        .{ .directory = "bochs/cpu/", .name = "init.cc" },
        .{ .directory = "bochs/cpu/", .name = "cpu.cc" },
        .{ .directory = "bochs/cpu/", .name = "event.cc" },
        .{ .directory = "bochs/cpu/", .name = "icache.cc" },
        .{ .directory = "bochs/cpu/decoder/", .name = "fetchdecode32.cc" },
        .{ .directory = "bochs/cpu/", .name = "access.cc" },
        .{ .directory = "bochs/cpu/", .name = "access2.cc" },
        .{ .directory = "bochs/cpu/", .name = "shift16.cc" },
        .{ .directory = "bochs/cpu/", .name = "logical16.cc" },
        .{ .directory = "bochs/cpu/", .name = "ctrl_xfer32.cc" },
        .{ .directory = "bochs/cpu/", .name = "ctrl_xfer16.cc" },
        .{ .directory = "bochs/cpu/", .name = "mmx.cc" },
        .{ .directory = "bochs/cpu/", .name = "3dnow.cc" },
        .{ .directory = "bochs/cpu/", .name = "fpu_emu.cc" },
        .{ .directory = "bochs/cpu/", .name = "sse.cc" },
        .{ .directory = "bochs/cpu/", .name = "sse_move.cc" },
        .{ .directory = "bochs/cpu/", .name = "sse_pfp.cc" },
        .{ .directory = "bochs/cpu/", .name = "sse_rcp.cc" },
        .{ .directory = "bochs/cpu/", .name = "sse_string.cc" },
        .{ .directory = "bochs/cpu/", .name = "xsave.cc" },
        .{ .directory = "bochs/cpu/", .name = "aes.cc" },
        .{ .directory = "bochs/cpu/", .name = "gf2.cc" },
        .{ .directory = "bochs/cpu/", .name = "sha.cc" },
        .{ .directory = "bochs/cpu/", .name = "svm.cc" },
        .{ .directory = "bochs/cpu/", .name = "vmx.cc" },
        .{ .directory = "bochs/cpu/", .name = "vmcs.cc" },
        .{ .directory = "bochs/cpu/", .name = "vmexit.cc" },
        .{ .directory = "bochs/cpu/", .name = "vmfunc.cc" },
        .{ .directory = "bochs/cpu/", .name = "soft_int.cc" },
        .{ .directory = "bochs/cpu/", .name = "apic.cc" },
        .{ .directory = "bochs/cpu/", .name = "bcd.cc" },
        .{ .directory = "bochs/cpu/", .name = "mult16.cc" },
        .{ .directory = "bochs/cpu/", .name = "tasking.cc" },
        .{ .directory = "bochs/cpu/", .name = "shift32.cc" },
        .{ .directory = "bochs/cpu/", .name = "shift8.cc" },
        .{ .directory = "bochs/cpu/", .name = "arith8.cc" },
        .{ .directory = "bochs/cpu/", .name = "stack.cc" },
        .{ .directory = "bochs/cpu/", .name = "stack16.cc" },
        .{ .directory = "bochs/cpu/", .name = "protect_ctrl.cc" },
        .{ .directory = "bochs/cpu/", .name = "mult8.cc" },
        .{ .directory = "bochs/cpu/", .name = "load.cc" },
        .{ .directory = "bochs/cpu/", .name = "data_xfer8.cc" },
        .{ .directory = "bochs/cpu/", .name = "vm8086.cc" },
        .{ .directory = "bochs/cpu/", .name = "logical8.cc" },
        .{ .directory = "bochs/cpu/", .name = "logical32.cc" },
        .{ .directory = "bochs/cpu/", .name = "arith16.cc" },
        .{ .directory = "bochs/cpu/", .name = "segment_ctrl.cc" },
        .{ .directory = "bochs/cpu/", .name = "data_xfer16.cc" },
        .{ .directory = "bochs/cpu/", .name = "data_xfer32.cc" },
        .{ .directory = "bochs/cpu/", .name = "exception.cc" },
        .{ .directory = "bochs/cpu/", .name = "cpuid.cc" },
        .{ .directory = "bochs/cpu/", .name = "generic_cpuid.cc" },
        .{ .directory = "bochs/cpu/", .name = "proc_ctrl.cc" },
        .{ .directory = "bochs/cpu/", .name = "mwait.cc" },
        .{ .directory = "bochs/cpu/", .name = "crregs.cc" },
        .{ .directory = "bochs/cpu/", .name = "cet.cc" },
        .{ .directory = "bochs/cpu/", .name = "msr.cc" },
        .{ .directory = "bochs/cpu/", .name = "smm.cc" },
        .{ .directory = "bochs/cpu/", .name = "flag_ctrl_pro.cc" },
        .{ .directory = "bochs/cpu/", .name = "stack32.cc" },
        .{ .directory = "bochs/cpu/", .name = "debugstuff.cc" },
        .{ .directory = "bochs/cpu/", .name = "flag_ctrl.cc" },
        .{ .directory = "bochs/cpu/", .name = "mult32.cc" },
        .{ .directory = "bochs/cpu/", .name = "arith32.cc" },
        .{ .directory = "bochs/cpu/", .name = "jmp_far.cc" },
        .{ .directory = "bochs/cpu/", .name = "call_far.cc" },
        .{ .directory = "bochs/cpu/", .name = "ret_far.cc" },
        .{ .directory = "bochs/cpu/", .name = "iret.cc" },
        .{ .directory = "bochs/cpu/", .name = "ctrl_xfer_pro.cc" },
        .{ .directory = "bochs/cpu/", .name = "segment_ctrl_pro.cc" },
        .{ .directory = "bochs/cpu/", .name = "io.cc" },
        .{ .directory = "bochs/cpu/", .name = "crc32.cc" },
        .{ .directory = "bochs/cpu/", .name = "bit.cc" },
        .{ .directory = "bochs/cpu/", .name = "bit16.cc" },
        .{ .directory = "bochs/cpu/", .name = "bit32.cc" },
        .{ .directory = "bochs/cpu/", .name = "bmi32.cc" },
        .{ .directory = "bochs/cpu/", .name = "string.cc" },
        .{ .directory = "bochs/cpu/", .name = "faststring.cc" },
        .{ .directory = "bochs/cpu/", .name = "paging.cc" },
        .{ .directory = "bochs/cpu/", .name = "rdrand.cc" },
        .{ .directory = "bochs/cpu/", .name = "wide_int.cc" },
        .{ .directory = "bochs/cpu/decoder/", .name = "disasm.cc" },
    };
    inline for (cpu_module_files) |file| {
        cpu_module.addCSourceFile(.{
            .file = file.toLazyPath(b) catch unreachable,
            .flags = &.{
                "-MJ",
                file.toTmpFileName(b) catch unreachable,
            },
            .language = .cpp,
        });
    }
    cpu_module.addCMacro("_FILE_OFFSET_BITS", "64");
    cpu_module.addCMacro("_LARGE_FILES", "");
    if (with_sdl) {
        cpu_module.addCMacro("_GNU_SOURCE", "1");
        cpu_module.addCMacro("_REENTRANT", "");
        cpu_module.linkSystemLibrary(
            "SDL",
            .{ .preferred_link_mode = .dynamic },
        );
    }

    const cpudb_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    cpudb_module.addIncludePath(b.path("bochs/generated/"));
    cpudb_module.addIncludePath(b.path("bochs/cpu/"));
    cpudb_module.addIncludePath(b.path("bochs/"));
    cpudb_module.addIncludePath(b.path("bochs/instrument/stubs/"));
    const cpudb_module_files: []const SourceFile = comptime &.{
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "pentium.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "pentium_mmx.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "p2_klamath.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "p3_katmai.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "p4_willamette.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "p4_prescott_celeron_336.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "atom_n270.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "core_duo_t2400_yonah.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "core2_penryn_t9600.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "corei5_lynnfield_750.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "corei5_arrandale_m520.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "corei7_sandy_bridge_2600K.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "corei7_ivy_bridge_3770K.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "corei7_haswell_4770.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "broadwell_ult.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "corei7_skylake-x.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "corei3_cnl.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "corei7_icelake-u.cc" },
        .{ .directory = "bochs/cpu/cpudb/intel/", .name = "tigerlake.cc" },
        .{ .directory = "bochs/cpu/cpudb/amd/", .name = "amd_k6_2_chomper.cc" },
        .{ .directory = "bochs/cpu/cpudb/amd/", .name = "athlon64_clawhammer.cc" },
        .{ .directory = "bochs/cpu/cpudb/amd/", .name = "athlon64_venice.cc" },
        .{ .directory = "bochs/cpu/cpudb/amd/", .name = "turion64_tyler.cc" },
        .{ .directory = "bochs/cpu/cpudb/amd/", .name = "phenomx3_8650_toliman.cc" },
        .{ .directory = "bochs/cpu/cpudb/amd/", .name = "trinity_apu.cc" },
        .{ .directory = "bochs/cpu/cpudb/amd/", .name = "zambezi.cc" },
        .{ .directory = "bochs/cpu/cpudb/amd/", .name = "ryzen.cc" },
    };
    inline for (cpudb_module_files) |file| {
        cpudb_module.addCSourceFile(.{
            .file = file.toLazyPath(b) catch unreachable,
            .flags = &.{
                "-MJ",
                file.toTmpFileName(b) catch unreachable,
            },
            .language = .cpp,
        });
    }
    cpudb_module.addCMacro("_FILE_OFFSET_BITS", "64");
    cpudb_module.addCMacro("_LARGE_FILES", "");
    if (with_sdl) {
        cpudb_module.addCMacro("_GNU_SOURCE", "1");
        cpudb_module.addCMacro("_REENTRANT", "");
        cpudb_module.linkSystemLibrary(
            "SDL",
            .{ .preferred_link_mode = .dynamic },
        );
    }

    const memory_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    memory_module.addIncludePath(b.path("bochs/generated/"));
    memory_module.addIncludePath(b.path("bochs/"));
    memory_module.addIncludePath(b.path("bochs/instrument/stubs/"));
    const memory_module_files: []const SourceFile = comptime &.{
        .{ .directory = "bochs/memory/", .name = "memory.cc" },
        .{ .directory = "bochs/memory/", .name = "misc_mem.cc" },
    };
    inline for (memory_module_files) |file| {
        memory_module.addCSourceFile(.{
            .file = file.toLazyPath(b) catch unreachable,
            .flags = &.{
                "-MJ",
                file.toTmpFileName(b) catch unreachable,
            },
            .language = .cpp,
        });
    }
    memory_module.addCMacro("_FILE_OFFSET_BITS", "64");
    memory_module.addCMacro("_LARGE_FILES", "");
    if (with_sdl) {
        memory_module.addCMacro("_GNU_SOURCE", "1");
        memory_module.addCMacro("_REENTRANT", "");
        memory_module.linkSystemLibrary(
            "SDL",
            .{ .preferred_link_mode = .dynamic },
        );
    }

    const gui_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    gui_module.addIncludePath(b.path("bochs/generated/"));
    gui_module.addIncludePath(b.path("bochs/"));
    gui_module.addIncludePath(b.path("bochs/iodev/"));
    gui_module.addIncludePath(b.path("bochs/instrument/stubs/"));
    const gui_module_files: []const SourceFile = comptime &.{
        .{ .directory = "bochs/gui/", .name = "keymap.cc" },
        .{ .directory = "bochs/gui/", .name = "gui.cc" },
        .{ .directory = "bochs/gui/", .name = "siminterface.cc" },
        .{ .directory = "bochs/gui/", .name = "paramtree.cc" },
        .{ .directory = "bochs/gui/", .name = "x.cc" },
        .{ .directory = "bochs/gui/", .name = "textconfig.cc" },
    };
    inline for (gui_module_files) |file| {
        gui_module.addCSourceFile(.{
            .file = file.toLazyPath(b) catch unreachable,
            .flags = &.{
                "-MJ",
                file.toTmpFileName(b) catch unreachable,
            },
            .language = .cpp,
        });
    }
    gui_module.addCMacro("_FILE_OFFSET_BITS", "64");
    gui_module.addCMacro("_LARGE_FILES", "");
    if (with_sdl) {
        memory_module.addCMacro("_GNU_SOURCE", "1");
        memory_module.addCMacro("_REENTRANT", "");
        memory_module.linkSystemLibrary(
            "SDL",
            .{ .preferred_link_mode = .dynamic },
        );
    }

    const fpu_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    fpu_module.addIncludePath(b.path("bochs/generated/"));
    fpu_module.addIncludePath(b.path("bochs/cpu/"));
    fpu_module.addIncludePath(b.path("bochs/"));
    fpu_module.addIncludePath(b.path("bochs/instrument/stubs/"));
    const fpu_module_files: []const SourceFile = comptime &.{
        .{ .directory = "bochs/cpu/fpu/", .name = "ferr.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "fpu.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "fpu_arith.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "fpu_compare.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "fpu_const.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "fpu_cmov.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "fpu_load_store.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "fpu_misc.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "fpu_trans.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "fprem.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "fsincos.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "f2xm1.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "fyl2x.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "fpatan.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "softfloat.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "softfloatx80.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "softfloat16.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "softfloat-muladd.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "softfloat-specialize.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "softfloat-round-pack.cc" },
        .{ .directory = "bochs/cpu/fpu/", .name = "poly.cc" },
    };
    inline for (fpu_module_files) |file| {
        fpu_module.addCSourceFile(.{
            .file = file.toLazyPath(b) catch unreachable,
            .flags = &.{
                "-MJ",
                file.toTmpFileName(b) catch unreachable,
            },
            .language = .cpp,
        });
    }
    fpu_module.addCMacro("_FILE_OFFSET_BITS", "64");
    fpu_module.addCMacro("_LARGE_FILES", "");
    if (with_sdl) {
        fpu_module.addCMacro("_GNU_SOURCE", "1");
        fpu_module.addCMacro("_REENTRANT", "");
        fpu_module.linkSystemLibrary(
            "SDL",
            .{ .preferred_link_mode = .dynamic },
        );
    }

    const bochs_mod = b.addModule("bochs", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    bochs_mod.addIncludePath(b.path("bochs/generated/"));
    bochs_mod.addIncludePath(b.path("bochs/instrument/stubs/"));
    bochs_mod.addIncludePath(b.path("bochs/"));
    const bochs_mod_files: []const SourceFile = comptime &.{
        .{ .directory = "bochs/", .name = "logio.cc" },
        .{ .directory = "bochs/", .name = "main.cc" },
        .{ .directory = "bochs/", .name = "config.cc" },
        .{ .directory = "bochs/", .name = "pc_system.cc" },
        .{ .directory = "bochs/", .name = "osdep.cc" },
        .{ .directory = "bochs/", .name = "plugin.cc" },
        .{ .directory = "bochs/", .name = "crc.cc" },
        .{ .directory = "bochs/", .name = "bxthread.cc" },
    };
    inline for (bochs_mod_files) |file| {
        bochs_mod.addCSourceFile(.{
            .file = file.toLazyPath(b) catch unreachable,
            .flags = &.{
                "-MJ",
                file.toTmpFileName(b) catch unreachable,
                "-Wno-date-time",
            },
            .language = .cpp,
        });
    }
    bochs_mod.addCMacro("_FILE_OFFSET_BITS", "64");
    bochs_mod.addCMacro("_LARGE_FILES", "");
    if (with_sdl) {
        bochs_mod.addCMacro("_GNU_SOURCE", "1");
        bochs_mod.addCMacro("_REENTRANT", "");
        bochs_mod.linkSystemLibrary(
            "SDL",
            .{ .preferred_link_mode = .dynamic },
        );
    }
    const bx_share_path: []const u8 = blk: {
        var buf: std.ArrayList(u8) = .empty;
        buf.appendSlice(b.allocator, "\"") catch @panic("OOM");
        buf.appendSlice(b.allocator, b.install_prefix) catch @panic("OOM");
        buf.appendSlice(b.allocator, "/bochs-share/") catch @panic("OOM");
        buf.appendSlice(b.allocator, "\"") catch @panic("OOM");

        break :blk buf.items;
    };
    bochs_mod.addCMacro("BX_SHARE_PATH", bx_share_path);

    // ********************************************************************* //
    // ******************* Creation of static libraries ******************** //
    // ********************************************************************* //

    const libiodev = b.addLibrary(.{
        .name = "iodev",
        .linkage = .static,
        .root_module = iodev_module,
    });
    b.installArtifact(libiodev);

    const libdisplay = b.addLibrary(.{
        .name = "display",
        .linkage = .static,
        .root_module = display_module,
    });
    b.installArtifact(libdisplay);

    const libhdimage = b.addLibrary(.{
        .name = "hdimage",
        .linkage = .static,
        .root_module = hdimage_module,
    });
    b.installArtifact(libhdimage);

    const libcpu = b.addLibrary(.{
        .name = "cpu",
        .linkage = .static,
        .root_module = cpu_module,
    });
    b.installArtifact(libcpu);

    const libcpudb = b.addLibrary(.{
        .name = "cpudb",
        .linkage = .static,
        .root_module = cpudb_module,
    });
    b.installArtifact(libcpudb);

    const libmemory = b.addLibrary(.{
        .name = "memory",
        .linkage = .static,
        .root_module = memory_module,
    });
    b.installArtifact(libmemory);

    const libgui = b.addLibrary(.{
        .name = "memory",
        .linkage = .static,
        .root_module = gui_module,
    });
    b.installArtifact(libgui);

    const libfpu = b.addLibrary(.{
        .name = "fpu",
        .linkage = .static,
        .root_module = fpu_module,
    });
    b.installArtifact(libfpu);

    // ********************************************************************* //
    // ******************* Creation of final executable ******************** //
    // ********************************************************************* //

    const bochsrc_install = b.addInstallFile(b.path("bochs/.bochsrc"), "bochs-share/.bochsrc");

    const share_files: []const SourceFile = comptime &.{
        .{ .name = "bios.bin-1.13.0", .directory = "bochs/bios/" },
        .{ .name = "BIOS-bochs-latest", .directory = "bochs/bios/" },
        .{ .name = "BIOS-bochs-legacy", .directory = "bochs/bios/" },
        .{ .name = "SeaBIOS-README", .directory = "bochs/bios/" },
        .{ .name = "SeaVGABIOS-README", .directory = "bochs/bios/" },
        .{ .name = "vgabios-cirrus.bin-1.13.0", .directory = "bochs/bios/" },
        .{ .name = "VGABIOS-elpin-2.40", .directory = "bochs/bios/" },
        .{ .name = "VGABIOS-elpin-LICENSE", .directory = "bochs/bios/" },
        .{ .name = "VGABIOS-lgpl-latest", .directory = "bochs/bios/" },
        .{ .name = "VGABIOS-lgpl-latest-debug", .directory = "bochs/bios/" },
        .{ .name = "VGABIOS-lgpl-README", .directory = "bochs/bios/" },
        .{ .name = "VGABIOS-lgpl-latest-banshee", .directory = "bochs/bios/" },
        .{ .name = "VGABIOS-lgpl-latest-cirrus", .directory = "bochs/bios/" },
        .{ .name = "VGABIOS-lgpl-latest-cirrus-debug", .directory = "bochs/bios/" },
        .{ .name = "keymaps/sdl-pc-de.map", .directory = "bochs/gui/" },
        .{ .name = "keymaps/sdl-pc-us.map", .directory = "bochs/gui/" },
        .{ .name = "keymaps/sdl2-pc-de.map", .directory = "bochs/gui/" },
        .{ .name = "keymaps/sdl2-pc-us.map", .directory = "bochs/gui/" },
        .{ .name = "keymaps/x11-pc-be.map", .directory = "bochs/gui/" },
        .{ .name = "keymaps/x11-pc-da.map", .directory = "bochs/gui/" },
        .{ .name = "keymaps/x11-pc-de.map", .directory = "bochs/gui/" },
        .{ .name = "keymaps/x11-pc-es.map", .directory = "bochs/gui/" },
        .{ .name = "keymaps/x11-pc-fr.map", .directory = "bochs/gui/" },
        .{ .name = "keymaps/x11-pc-it.map", .directory = "bochs/gui/" },
        .{ .name = "keymaps/x11-pc-ru.map", .directory = "bochs/gui/" },
        .{ .name = "keymaps/x11-pc-se.map", .directory = "bochs/gui/" },
        .{ .name = "keymaps/x11-pc-sg.map", .directory = "bochs/gui/" },
        .{ .name = "keymaps/x11-pc-si.map", .directory = "bochs/gui/" },
        .{ .name = "keymaps/x11-pc-uk.map", .directory = "bochs/gui/" },
        .{ .name = "keymaps/x11-pc-us.map", .directory = "bochs/gui/" },
    };

    const bochs = b.addExecutable(.{
        .name = "bochs",
        .root_module = bochs_mod,
    });
    bochs.linkLibrary(libiodev);
    bochs.linkLibrary(libdisplay);
    bochs.linkLibrary(libhdimage);
    bochs.linkLibrary(libcpu);
    bochs.linkLibrary(libcpudb);
    bochs.linkLibrary(libmemory);
    bochs.linkLibrary(libgui);
    bochs.linkLibrary(libfpu);
    if (with_x11) {
        bochs.linkSystemLibrary("X11");
        bochs.linkSystemLibrary("Xpm");
        bochs.linkSystemLibrary("Xrandr");
    }
    bochs.step.dependOn(&bochsrc_install.step);
    inline for (share_files) |file| {
        const install = b.addInstallFile(
            file.toLazyPath(b) catch @panic("OOM"),
            "bochs-share/" ++ file.name,
        );
        bochs.step.dependOn(&install.step);
    }
    b.installArtifact(bochs);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(bochs);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run Bochs");
    run_step.dependOn(&run_cmd.step);

    // ******************** Compilation Database Cleanup ******************** //

    const compile_db_step = b.step(
        "compiledb",
        "Build & format compile_commands.json",
    );
    const modcompiledb = b.createModule(.{
        .root_source_file = b.path("cleandb/main.zig"),
        .target = std.Build.resolveTargetQuery(b, std.Target.Query.fromTarget(&builtin.target)),
        .optimize = optimize,
    });
    const execompiledb = b.addExecutable(.{
        .name = "compiledb",
        .root_module = modcompiledb,
    });
    const runcompiledb = b.addRunArtifact(execompiledb);
    runcompiledb.addArg(
        std.process.getCwdAlloc(b.allocator) catch unreachable,
    );
    runcompiledb.step.dependOn(&bochs.step);
    compile_db_step.dependOn(&runcompiledb.step);
    b.getInstallStep().dependOn(compile_db_step);
}
