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
    hdimage_module.addCSourceFiles(.{
        .files = &.{
            "iodev/hdimage/hdimage.cc",
            "iodev/hdimage/cdrom.cc",
            "iodev/hdimage/cdrom_misc.cc",
            "iodev/hdimage/vbox.cc",
            "iodev/hdimage/vmware3.cc",
            "iodev/hdimage/vmware4.cc",
            "iodev/hdimage/vpc.cc",
            "iodev/hdimage/vvfat.cc",
        },
        .flags = &.{},
        .language = .cpp,
    });
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
    cpu_module.addCSourceFiles(.{
        .files = &.{
            "cpu/init.cc",
            "cpu/cpu.cc",
            "cpu/event.cc",
            "cpu/icache.cc",
            "cpu/decoder/fetchdecode32.cc",
            "cpu/access.cc",
            "cpu/access2.cc",
            "cpu/shift16.cc",
            "cpu/logical16.cc",
            "cpu/ctrl_xfer32.cc",
            "cpu/ctrl_xfer16.cc",
            "cpu/mmx.cc",
            "cpu/3dnow.cc",
            "cpu/fpu_emu.cc",
            "cpu/sse.cc",
            "cpu/sse_move.cc",
            "cpu/sse_pfp.cc",
            "cpu/sse_rcp.cc",
            "cpu/sse_string.cc",
            "cpu/xsave.cc",
            "cpu/aes.cc",
            "cpu/gf2.cc",
            "cpu/sha.cc",
            "cpu/svm.cc",
            "cpu/vmx.cc",
            "cpu/vmcs.cc",
            "cpu/vmexit.cc",
            "cpu/vmfunc.cc",
            "cpu/soft_int.cc",
            "cpu/apic.cc",
            "cpu/bcd.cc",
            "cpu/mult16.cc",
            "cpu/tasking.cc",
            "cpu/shift32.cc",
            "cpu/shift8.cc",
            "cpu/arith8.cc",
            "cpu/stack.cc",
            "cpu/stack16.cc",
            "cpu/protect_ctrl.cc",
            "cpu/mult8.cc",
            "cpu/load.cc",
            "cpu/data_xfer8.cc",
            "cpu/vm8086.cc",
            "cpu/logical8.cc",
            "cpu/logical32.cc",
            "cpu/arith16.cc",
            "cpu/segment_ctrl.cc",
            "cpu/data_xfer16.cc",
            "cpu/data_xfer32.cc",
            "cpu/exception.cc",
            "cpu/cpuid.cc",
            "cpu/generic_cpuid.cc",
            "cpu/proc_ctrl.cc",
            "cpu/mwait.cc",
            "cpu/crregs.cc",
            "cpu/cet.cc",
            "cpu/msr.cc",
            "cpu/smm.cc",
            "cpu/flag_ctrl_pro.cc",
            "cpu/stack32.cc",
            "cpu/debugstuff.cc",
            "cpu/flag_ctrl.cc",
            "cpu/mult32.cc",
            "cpu/arith32.cc",
            "cpu/jmp_far.cc",
            "cpu/call_far.cc",
            "cpu/ret_far.cc",
            "cpu/iret.cc",
            "cpu/ctrl_xfer_pro.cc",
            "cpu/segment_ctrl_pro.cc",
            "cpu/io.cc",
            "cpu/crc32.cc",
            "cpu/bit.cc",
            "cpu/bit16.cc",
            "cpu/bit32.cc",
            "cpu/bmi32.cc",
            "cpu/string.cc",
            "cpu/faststring.cc",
            "cpu/paging.cc",
            "cpu/rdrand.cc",
            "cpu/wide_int.cc",
            "cpu/decoder/disasm.cc",
        },
        .flags = &.{},
        .language = .cpp,
    });
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
    cpudb_module.addCSourceFiles(.{
        .files = &.{
            "cpu/cpudb/intel/pentium.cc",
            "cpu/cpudb/intel/pentium_mmx.cc",
            "cpu/cpudb/intel/p2_klamath.cc",
            "cpu/cpudb/intel/p3_katmai.cc",
            "cpu/cpudb/intel/p4_willamette.cc",
            "cpu/cpudb/intel/p4_prescott_celeron_336.cc",
            "cpu/cpudb/intel/atom_n270.cc",
            "cpu/cpudb/intel/core_duo_t2400_yonah.cc",
            "cpu/cpudb/intel/core2_penryn_t9600.cc",
            "cpu/cpudb/intel/corei5_lynnfield_750.cc",
            "cpu/cpudb/intel/corei5_arrandale_m520.cc",
            "cpu/cpudb/intel/corei7_sandy_bridge_2600K.cc",
            "cpu/cpudb/intel/corei7_ivy_bridge_3770K.cc",
            "cpu/cpudb/intel/corei7_haswell_4770.cc",
            "cpu/cpudb/intel/broadwell_ult.cc",
            "cpu/cpudb/intel/corei7_skylake-x.cc",
            "cpu/cpudb/intel/corei3_cnl.cc",
            "cpu/cpudb/intel/corei7_icelake-u.cc",
            "cpu/cpudb/intel/tigerlake.cc",
            "cpu/cpudb/amd/amd_k6_2_chomper.cc",
            "cpu/cpudb/amd/athlon64_clawhammer.cc",
            "cpu/cpudb/amd/athlon64_venice.cc",
            "cpu/cpudb/amd/turion64_tyler.cc",
            "cpu/cpudb/amd/phenomx3_8650_toliman.cc",
            "cpu/cpudb/amd/trinity_apu.cc",
            "cpu/cpudb/amd/zambezi.cc",
            "cpu/cpudb/amd/ryzen.cc",
        },
        .flags = &.{},
        .language = .cpp,
    });
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
    memory_module.addCSourceFiles(.{
        .files = &.{
            "memory/memory.cc",
            "memory/misc_mem.cc",
        },
        .flags = &.{},
        .language = .cpp,
    });
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
    gui_module.addCSourceFiles(.{
        .files = &.{
            "gui/keymap.cc",
            "gui/gui.cc",
            "gui/siminterface.cc",
            "gui/paramtree.cc",
            "gui/x.cc",
            "gui/textconfig.cc",
        },
        .flags = &.{},
        .language = .cpp,
    });
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
    fpu_module.addCSourceFiles(.{
        .files = &.{
            "cpu/fpu/ferr.cc",
            "cpu/fpu/fpu.cc",
            "cpu/fpu/fpu_arith.cc",
            "cpu/fpu/fpu_compare.cc",
            "cpu/fpu/fpu_const.cc",
            "cpu/fpu/fpu_cmov.cc",
            "cpu/fpu/fpu_load_store.cc",
            "cpu/fpu/fpu_misc.cc",
            "cpu/fpu/fpu_trans.cc",
            "cpu/fpu/fprem.cc",
            "cpu/fpu/fsincos.cc",
            "cpu/fpu/f2xm1.cc",
            "cpu/fpu/fyl2x.cc",
            "cpu/fpu/fpatan.cc",
            "cpu/fpu/softfloat.cc",
            "cpu/fpu/softfloatx80.cc",
            "cpu/fpu/softfloat16.cc",
            "cpu/fpu/softfloat-muladd.cc",
            "cpu/fpu/softfloat-specialize.cc",
            "cpu/fpu/softfloat-round-pack.cc",
            "cpu/fpu/poly.cc",
        },
        .flags = &.{},
        .language = .cpp,
    });
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
    bochs_mod.addCSourceFiles(.{
        .files = &.{
            "logio.cc",
            "main.cc",
            "config.cc",
            "pc_system.cc",
            "osdep.cc",
            "plugin.cc",
            "crc.cc",
            "bxthread.cc",
        },
        .flags = &.{},
        .language = .cpp,
    });
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
