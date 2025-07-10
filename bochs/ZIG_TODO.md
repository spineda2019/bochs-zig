# TODO
Tracking pending tasks here to fully port the build to zig

I need to port configure script options to zig build system, here are the ones
I can see so far:

```
Fine tuning of the installation directories:
  --bindir=DIR            user executables [EPREFIX/bin]
  --sbindir=DIR           system admin executables [EPREFIX/sbin]
  --libexecdir=DIR        program executables [EPREFIX/libexec]
  --sysconfdir=DIR        read-only single-machine data [PREFIX/etc]
  --sharedstatedir=DIR    modifiable architecture-independent data [PREFIX/com]
  --localstatedir=DIR     modifiable single-machine data [PREFIX/var]
  --libdir=DIR            object code libraries [EPREFIX/lib]
  --includedir=DIR        C header files [PREFIX/include]
  --oldincludedir=DIR     C header files for non-gcc [/usr/include]
  --datarootdir=DIR       read-only arch.-independent data root [PREFIX/share]
  --datadir=DIR           read-only architecture-independent data [DATAROOTDIR]
  --infodir=DIR           info documentation [DATAROOTDIR/info]
  --localedir=DIR         locale-dependent data [DATAROOTDIR/locale]
  --mandir=DIR            man documentation [DATAROOTDIR/man]
  --docdir=DIR            documentation root [DATAROOTDIR/doc/PACKAGE]
  --htmldir=DIR           html documentation [DOCDIR]
  --dvidir=DIR            dvi documentation [DOCDIR]
  --pdfdir=DIR            pdf documentation [DOCDIR]
  --psdir=DIR             ps documentation [DOCDIR]

X features:
  --x-includes=DIR    X include files are in DIR
  --x-libraries=DIR   X library files are in DIR

System types:
  --build=BUILD     configure for building on BUILD [guessed]
  --host=HOST       cross-compile to build programs to run on HOST [BUILD]
  --target=TARGET   configure for building compilers for TARGET [HOST]

Optional Features:
  --disable-option-checking  ignore unrecognized --enable/--with options
  --disable-FEATURE       do not include FEATURE (same as --enable-FEATURE=no)
  --enable-FEATURE[=ARG]  include FEATURE [ARG=yes]
  --enable-static[=PKGS]  build static libraries [default=no]
  --enable-shared[=PKGS]  build shared libraries [default=yes]
  --enable-fast-install[=PKGS]
                          optimize for fast installation [default=yes]
  --disable-libtool-lock  avoid locking (might break parallel builds)
  --enable-ltdl-install   install libltdl
  --disable-largefile     omit support for large files
  --enable-idle-hack      use Roland Mainz's idle hack (no)
  --enable-plugins        enable plugin support (no)
  --enable-a20-pin        compile in support for A20 pin (yes)
  --enable-x86-64         compile in support for x86-64 instructions (no)
  --enable-smp            compile in support for SMP configurations (no)
  --enable-cpu-level      select cpu level (3,4,5,6 - default is 6)
  --enable-long-phy-address
                          compile in support for physical address larger than
                          32 bit (yes, if cpu level >= 5)
  --enable-large-ramfile  enable large ramfile support (yes)
  --enable-repeat-speedups
                          support repeated IO and mem copy speedups (no)
  --enable-fast-function-calls
                          support for fast function calls (no - gcc on x86 and
                          MSVC nmake only)
  --enable-handlers-chaining
                          support handlers-chaining emulation speedups (no)
  --enable-trace-linking  enable trace linking speedups support (no)
  --enable-configurable-msrs
                          support for configurable MSR registers (yes if cpu
                          level >= 5)
  --enable-show-ips       show IPS in Bochs status bar / log file (yes)
  --enable-cpp            use .cpp as C++ suffix (no)
  --enable-debugger       compile in support for Bochs internal debugger (no)
  --enable-debugger-gui   compile in support for Bochs internal debugger GUI
                          (yes, if debugger is on)
  --enable-gdb-stub       enable gdb stub support (no)
  --enable-iodebug        enable I/O interface to debugger (yes, if debugger
                          is on)
  --enable-all-optimizations
                          compile in all possible optimizations (no)
  --enable-readline       use readline library, if available (no)
  --enable-instrumentation=instrument-dir
                          compile in support for instrumentation (no)
  --enable-logging        enable logging (yes)
  --enable-stats          enable statistics collection (yes)
  --enable-assert-checks  enable BX_ASSERT checks (yes, if debugger is on)
  --enable-fpu            compile in FPU emulation (yes)
  --enable-vmx            VMX (virtualization extensions) emulation
                          (--enable-vmx=[no|1|2])
  --enable-svm            SVM (AMD: secure virtual machine) emulation (no)
  --enable-protection-keys
                          User-Mode Protection Keys support (no)
  --enable-cet            Control Flow Enforcement Technology support (no)
  --enable-3dnow          3DNow! support (no - incomplete)
  --enable-alignment-check
                          alignment check (#AC) support (yes, if cpu level >
                          3)
  --enable-monitor-mwait  support for MONITOR/MWAIT instructions (yes, if cpu
                          level > 5 - experimental)
  --enable-perfmon        support for limited hardware performance monitoring
                          emulation (yes, if cpu level > 5 - experimental)
  --enable-memtype        support for memory type
  --enable-avx            support for AVX instructions (no)
  --enable-evex           support for EVEX prefix and AVX-512 extensions (no)
  --enable-x86-debugger   x86 debugger support (no)
  --enable-pci            enable i440FX PCI support (yes)
  --enable-pcidev         enable PCI host device mapping support (no - linux
                          host only)
  --enable-usb            enable USB UHCI support (no)
  --enable-usb-ohci       enable USB OHCI support (no)
  --enable-usb-ehci       enable USB EHCI support (no)
  --enable-usb-xhci       enable USB xHCI support (no)
  --enable-ne2000         enable NE2000 support (no)
  --enable-pnic           enable PCI pseudo NIC support (no)
  --enable-e1000          enable Intel(R) Gigabit Ethernet support (no)
  --enable-raw-serial     use raw serial port access (no - incomplete)
  --enable-clgd54xx       enable CLGD54XX emulation (no)
  --enable-voodoo         enable 3dfx Voodoo Graphics emulation (no)
  --enable-cdrom          lowlevel CDROM support (yes)
  --enable-sb16           Sound Blaster 16 Support (no)
  --enable-es1370         enable ES1370 soundcard support (no)
  --enable-gameport       enable standard PC gameport support (yes, if
                          soundcard present)
  --enable-busmouse       enable Busmouse support (InPort & Standard)
  --enable-docbook        build the Docbook documentation (yes, if docbook
                          present)
  --enable-xpm            enable the check for XPM support (yes)

Optional Packages:
  --with-PACKAGE[=ARG]    use PACKAGE [ARG=yes]
  --without-PACKAGE       do not use PACKAGE (same as --with-PACKAGE=no)
  --with-gnu-ld           assume the C compiler uses GNU ld [default=no]
  --with-pic              try to use only PIC/non-PIC objects [default=use
                          both]
  --with-tags[=TAGS]      include additional configurations [automatic]
  --with-x                use the X Window System
  --with-x11                        use X11 GUI
  --with-win32                      use Win32 GUI
  --with-macos                      use Macintosh/CodeWarrior environment
  --with-carbon                     compile for MacOS X with Carbon GUI
  --with-nogui                      no native GUI, just use blank stubs
  --with-term                       textmode terminal environment
  --with-rfb                        use RFB protocol, works with VNC viewer
  --with-vncsrv                     use LibVNCServer, works with VNC viewer
  --with-amigaos                    use AmigaOS (or MorphOS) GUI
  --with-sdl                        use SDL libraries
  --with-sdl2                       use SDL2 libraries
  --with-wx                         use wxWidgets libraries
  --with-all-libs                   compile all guis that Bochs supports
```
