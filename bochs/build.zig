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
    // *** Individual Modules (1:1 mapping to old Makefiles static libs) *** //
    // ********************************************************************* //

    const iodev_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    iodev_module.addIncludePath(b.path("generated/"));
    iodev_module.addIncludePath(b.path("."));
    iodev_module.addIncludePath(b.path("instrument/stubs/"));
    const iodev_module_files: []const SourceFile = comptime &.{
        .{ .directory = "iodev/", .name = "devices.cc" },
        .{ .directory = "iodev/", .name = "virt_timer.cc" },
        .{ .directory = "iodev/", .name = "slowdown_timer.cc" },
        .{ .directory = "iodev/", .name = "pic.cc" },
        .{ .directory = "iodev/", .name = "pit.cc" },
        .{ .directory = "iodev/", .name = "serial.cc" },
        .{ .directory = "iodev/", .name = "parallel.cc" },
        .{ .directory = "iodev/", .name = "floppy.cc" },
        .{ .directory = "iodev/", .name = "keyboard.cc" },
        .{ .directory = "iodev/", .name = "biosdev.cc" },
        .{ .directory = "iodev/", .name = "cmos.cc" },
        .{ .directory = "iodev/", .name = "harddrv.cc" },
        .{ .directory = "iodev/", .name = "dma.cc" },
        .{ .directory = "iodev/", .name = "unmapped.cc" },
        .{ .directory = "iodev/", .name = "extfpuirq.cc" },
        .{ .directory = "iodev/", .name = "speaker.cc" },
        .{ .directory = "iodev/", .name = "ioapic.cc" },
        .{ .directory = "iodev/", .name = "pci.cc" },
        .{ .directory = "iodev/", .name = "pci2isa.cc" },
        .{ .directory = "iodev/", .name = "pci_ide.cc" },
        .{ .directory = "iodev/", .name = "acpi.cc" },
        .{ .directory = "iodev/", .name = "hpet.cc" },
        .{ .directory = "iodev/", .name = "pit82c54.cc" },
        .{ .directory = "iodev/", .name = "scancodes.cc" },
        .{ .directory = "iodev/", .name = "serial_raw.cc" },
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

    const display_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    display_module.addIncludePath(b.path("generated/"));
    display_module.addIncludePath(b.path("iodev/"));
    display_module.addIncludePath(b.path("."));
    display_module.addIncludePath(b.path("instrument/stubs/"));
    const display_module_files: []const SourceFile = comptime &.{
        .{ .directory = "iodev/display/", .name = "vga.cc" },
        .{ .directory = "iodev/display/", .name = "vgacore.cc" },
        .{ .directory = "iodev/display/", .name = "ddc.cc" },
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

    const hdimage_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    hdimage_module.addIncludePath(b.path("generated/"));
    hdimage_module.addIncludePath(b.path("iodev/"));
    hdimage_module.addIncludePath(b.path("."));
    hdimage_module.addIncludePath(b.path("instrument/stubs/"));
    const hdimage_module_files: []const SourceFile = comptime &.{
        .{ .directory = "iodev/hdimage/", .name = "hdimage.cc" },
        .{ .directory = "iodev/hdimage/", .name = "cdrom.cc" },
        .{ .directory = "iodev/hdimage/", .name = "cdrom_misc.cc" },
        .{ .directory = "iodev/hdimage/", .name = "vbox.cc" },
        .{ .directory = "iodev/hdimage/", .name = "vmware3.cc" },
        .{ .directory = "iodev/hdimage/", .name = "vmware4.cc" },
        .{ .directory = "iodev/hdimage/", .name = "vpc.cc" },
        .{ .directory = "iodev/hdimage/", .name = "vvfat.cc" },
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

    const cpu_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    cpu_module.addIncludePath(b.path("generated/"));
    cpu_module.addIncludePath(b.path("."));
    cpu_module.addIncludePath(b.path("instrument/stubs/"));
    const cpu_module_files: []const SourceFile = comptime &.{
        .{ .directory = "cpu/", .name = "init.cc" },
        .{ .directory = "cpu/", .name = "cpu.cc" },
        .{ .directory = "cpu/", .name = "event.cc" },
        .{ .directory = "cpu/", .name = "icache.cc" },
        .{ .directory = "cpu/decoder/", .name = "fetchdecode32.cc" },
        .{ .directory = "cpu/", .name = "access.cc" },
        .{ .directory = "cpu/", .name = "access2.cc" },
        .{ .directory = "cpu/", .name = "shift16.cc" },
        .{ .directory = "cpu/", .name = "logical16.cc" },
        .{ .directory = "cpu/", .name = "ctrl_xfer32.cc" },
        .{ .directory = "cpu/", .name = "ctrl_xfer16.cc" },
        .{ .directory = "cpu/", .name = "mmx.cc" },
        .{ .directory = "cpu/", .name = "3dnow.cc" },
        .{ .directory = "cpu/", .name = "fpu_emu.cc" },
        .{ .directory = "cpu/", .name = "sse.cc" },
        .{ .directory = "cpu/", .name = "sse_move.cc" },
        .{ .directory = "cpu/", .name = "sse_pfp.cc" },
        .{ .directory = "cpu/", .name = "sse_rcp.cc" },
        .{ .directory = "cpu/", .name = "sse_string.cc" },
        .{ .directory = "cpu/", .name = "xsave.cc" },
        .{ .directory = "cpu/", .name = "aes.cc" },
        .{ .directory = "cpu/", .name = "gf2.cc" },
        .{ .directory = "cpu/", .name = "sha.cc" },
        .{ .directory = "cpu/", .name = "svm.cc" },
        .{ .directory = "cpu/", .name = "vmx.cc" },
        .{ .directory = "cpu/", .name = "vmcs.cc" },
        .{ .directory = "cpu/", .name = "vmexit.cc" },
        .{ .directory = "cpu/", .name = "vmfunc.cc" },
        .{ .directory = "cpu/", .name = "soft_int.cc" },
        .{ .directory = "cpu/", .name = "apic.cc" },
        .{ .directory = "cpu/", .name = "bcd.cc" },
        .{ .directory = "cpu/", .name = "mult16.cc" },
        .{ .directory = "cpu/", .name = "tasking.cc" },
        .{ .directory = "cpu/", .name = "shift32.cc" },
        .{ .directory = "cpu/", .name = "shift8.cc" },
        .{ .directory = "cpu/", .name = "arith8.cc" },
        .{ .directory = "cpu/", .name = "stack.cc" },
        .{ .directory = "cpu/", .name = "stack16.cc" },
        .{ .directory = "cpu/", .name = "protect_ctrl.cc" },
        .{ .directory = "cpu/", .name = "mult8.cc" },
        .{ .directory = "cpu/", .name = "load.cc" },
        .{ .directory = "cpu/", .name = "data_xfer8.cc" },
        .{ .directory = "cpu/", .name = "vm8086.cc" },
        .{ .directory = "cpu/", .name = "logical8.cc" },
        .{ .directory = "cpu/", .name = "logical32.cc" },
        .{ .directory = "cpu/", .name = "arith16.cc" },
        .{ .directory = "cpu/", .name = "segment_ctrl.cc" },
        .{ .directory = "cpu/", .name = "data_xfer16.cc" },
        .{ .directory = "cpu/", .name = "data_xfer32.cc" },
        .{ .directory = "cpu/", .name = "exception.cc" },
        .{ .directory = "cpu/", .name = "cpuid.cc" },
        .{ .directory = "cpu/", .name = "generic_cpuid.cc" },
        .{ .directory = "cpu/", .name = "proc_ctrl.cc" },
        .{ .directory = "cpu/", .name = "mwait.cc" },
        .{ .directory = "cpu/", .name = "crregs.cc" },
        .{ .directory = "cpu/", .name = "cet.cc" },
        .{ .directory = "cpu/", .name = "msr.cc" },
        .{ .directory = "cpu/", .name = "smm.cc" },
        .{ .directory = "cpu/", .name = "flag_ctrl_pro.cc" },
        .{ .directory = "cpu/", .name = "stack32.cc" },
        .{ .directory = "cpu/", .name = "debugstuff.cc" },
        .{ .directory = "cpu/", .name = "flag_ctrl.cc" },
        .{ .directory = "cpu/", .name = "mult32.cc" },
        .{ .directory = "cpu/", .name = "arith32.cc" },
        .{ .directory = "cpu/", .name = "jmp_far.cc" },
        .{ .directory = "cpu/", .name = "call_far.cc" },
        .{ .directory = "cpu/", .name = "ret_far.cc" },
        .{ .directory = "cpu/", .name = "iret.cc" },
        .{ .directory = "cpu/", .name = "ctrl_xfer_pro.cc" },
        .{ .directory = "cpu/", .name = "segment_ctrl_pro.cc" },
        .{ .directory = "cpu/", .name = "io.cc" },
        .{ .directory = "cpu/", .name = "crc32.cc" },
        .{ .directory = "cpu/", .name = "bit.cc" },
        .{ .directory = "cpu/", .name = "bit16.cc" },
        .{ .directory = "cpu/", .name = "bit32.cc" },
        .{ .directory = "cpu/", .name = "bmi32.cc" },
        .{ .directory = "cpu/", .name = "string.cc" },
        .{ .directory = "cpu/", .name = "faststring.cc" },
        .{ .directory = "cpu/", .name = "paging.cc" },
        .{ .directory = "cpu/", .name = "rdrand.cc" },
        .{ .directory = "cpu/", .name = "wide_int.cc" },
        .{ .directory = "cpu/decoder/", .name = "disasm.cc" },
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

    const cpudb_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    cpudb_module.addIncludePath(b.path("generated/"));
    cpudb_module.addIncludePath(b.path("cpu/"));
    cpudb_module.addIncludePath(b.path("."));
    cpudb_module.addIncludePath(b.path("instrument/stubs/"));
    const cpudb_module_files: []const SourceFile = comptime &.{
        .{ .directory = "cpu/cpudb/intel/", .name = "pentium.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "pentium_mmx.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "p2_klamath.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "p3_katmai.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "p4_willamette.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "p4_prescott_celeron_336.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "atom_n270.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "core_duo_t2400_yonah.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "core2_penryn_t9600.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "corei5_lynnfield_750.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "corei5_arrandale_m520.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "corei7_sandy_bridge_2600K.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "corei7_ivy_bridge_3770K.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "corei7_haswell_4770.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "broadwell_ult.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "corei7_skylake-x.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "corei3_cnl.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "corei7_icelake-u.cc" },
        .{ .directory = "cpu/cpudb/intel/", .name = "tigerlake.cc" },
        .{ .directory = "cpu/cpudb/amd/", .name = "amd_k6_2_chomper.cc" },
        .{ .directory = "cpu/cpudb/amd/", .name = "athlon64_clawhammer.cc" },
        .{ .directory = "cpu/cpudb/amd/", .name = "athlon64_venice.cc" },
        .{ .directory = "cpu/cpudb/amd/", .name = "turion64_tyler.cc" },
        .{ .directory = "cpu/cpudb/amd/", .name = "phenomx3_8650_toliman.cc" },
        .{ .directory = "cpu/cpudb/amd/", .name = "trinity_apu.cc" },
        .{ .directory = "cpu/cpudb/amd/", .name = "zambezi.cc" },
        .{ .directory = "cpu/cpudb/amd/", .name = "ryzen.cc" },
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

    const memory_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    memory_module.addIncludePath(b.path("generated/"));
    memory_module.addIncludePath(b.path("."));
    memory_module.addIncludePath(b.path("instrument/stubs/"));
    const memory_module_files: []const SourceFile = comptime &.{
        .{ .directory = "memory/", .name = "memory.cc" },
        .{ .directory = "memory/", .name = "misc_mem.cc" },
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

    const gui_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    gui_module.addIncludePath(b.path("generated/"));
    gui_module.addIncludePath(b.path("."));
    gui_module.addIncludePath(b.path("iodev/"));
    gui_module.addIncludePath(b.path("instrument/stubs/"));
    const gui_module_files: []const SourceFile = comptime &.{
        .{ .directory = "gui/", .name = "keymap.cc" },
        .{ .directory = "gui/", .name = "gui.cc" },
        .{ .directory = "gui/", .name = "siminterface.cc" },
        .{ .directory = "gui/", .name = "paramtree.cc" },
        .{ .directory = "gui/", .name = "x.cc" },
        .{ .directory = "gui/", .name = "textconfig.cc" },
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

    const fpu_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    fpu_module.addIncludePath(b.path("generated/"));
    fpu_module.addIncludePath(b.path("cpu/"));
    fpu_module.addIncludePath(b.path("."));
    fpu_module.addIncludePath(b.path("instrument/stubs/"));
    const fpu_module_files: []const SourceFile = comptime &.{
        .{ .directory = "cpu/fpu/", .name = "ferr.cc" },
        .{ .directory = "cpu/fpu/", .name = "fpu.cc" },
        .{ .directory = "cpu/fpu/", .name = "fpu_arith.cc" },
        .{ .directory = "cpu/fpu/", .name = "fpu_compare.cc" },
        .{ .directory = "cpu/fpu/", .name = "fpu_const.cc" },
        .{ .directory = "cpu/fpu/", .name = "fpu_cmov.cc" },
        .{ .directory = "cpu/fpu/", .name = "fpu_load_store.cc" },
        .{ .directory = "cpu/fpu/", .name = "fpu_misc.cc" },
        .{ .directory = "cpu/fpu/", .name = "fpu_trans.cc" },
        .{ .directory = "cpu/fpu/", .name = "fprem.cc" },
        .{ .directory = "cpu/fpu/", .name = "fsincos.cc" },
        .{ .directory = "cpu/fpu/", .name = "f2xm1.cc" },
        .{ .directory = "cpu/fpu/", .name = "fyl2x.cc" },
        .{ .directory = "cpu/fpu/", .name = "fpatan.cc" },
        .{ .directory = "cpu/fpu/", .name = "softfloat.cc" },
        .{ .directory = "cpu/fpu/", .name = "softfloatx80.cc" },
        .{ .directory = "cpu/fpu/", .name = "softfloat16.cc" },
        .{ .directory = "cpu/fpu/", .name = "softfloat-muladd.cc" },
        .{ .directory = "cpu/fpu/", .name = "softfloat-specialize.cc" },
        .{ .directory = "cpu/fpu/", .name = "softfloat-round-pack.cc" },
        .{ .directory = "cpu/fpu/", .name = "poly.cc" },
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

    const bochs_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    bochs_mod.addIncludePath(b.path("generated/"));
    bochs_mod.addIncludePath(b.path("instrument/stubs/"));
    bochs_mod.addIncludePath(b.path("."));
    const bochs_mod_files: []const SourceFile = comptime &.{
        .{ .directory = "", .name = "logio.cc" },
        .{ .directory = "", .name = "main.cc" },
        .{ .directory = "", .name = "config.cc" },
        .{ .directory = "", .name = "pc_system.cc" },
        .{ .directory = "", .name = "osdep.cc" },
        .{ .directory = "", .name = "plugin.cc" },
        .{ .directory = "", .name = "crc.cc" },
        .{ .directory = "", .name = "bxthread.cc" },
    };
    inline for (bochs_mod_files) |file| {
        bochs_mod.addCSourceFile(.{
            .file = file.toLazyPath(b) catch unreachable,
            .flags = &.{
                "-MJ",
                file.toTmpFileName(b) catch unreachable,
            },
            .language = .cpp,
        });
    }
    bochs_mod.addCMacro("_FILE_OFFSET_BITS", "64");
    bochs_mod.addCMacro("_LARGE_FILES", "");
    const bx_share_path: []const u8 = blk: {
        var buf: std.ArrayList(u8) = .empty;
        buf.appendSlice(b.allocator, "\"") catch @panic("OOM");
        buf.appendSlice(b.allocator, b.install_prefix) catch @panic("OOM");
        buf.appendSlice(b.allocator, "bochs-share/") catch @panic("OOM");
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
    bochs.linkSystemLibrary("X11");
    bochs.linkSystemLibrary("Xpm");
    bochs.linkSystemLibrary("Xrandr");
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
