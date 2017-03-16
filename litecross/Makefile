
OUTPUT = $(CURDIR)/output

BINUTILS_SRCDIR = BINUTILS_SRCDIR_not_set
GCC_SRCDIR = GCC_SRCDIR_not_set
MINGW_SRCDIR = MINGW_SRCDIR_not_set

GCC_CONFIG_FOR_TARGET = 
COMMON_CONFIG = 
GCC_CONFIG = 
TOOLCHAIN_CONFIG = 

XGCC_DIR = $(CURDIR)/obj_toolchain/gcc
XGCC = $(XGCC_DIR)/xgcc -B $(XGCC_DIR)
XCPP = $(XGCC_DIR)/cpp -B $(XGCC_DIR)
XAR  = $(CURDIR)/obj_toolchain/binutils/ar
XRANLIB  = $(CURDIR)/obj_toolchain/binutils/ranlib

-include config.mak


MAKE += MULTILIB_OSDIRNAMES=
MAKE += INFO_DEPS= infodir=
MAKE += ac_cv_prog_lex_root=lex.yy.c
MAKE += MAKEINFO=false

FULL_TOOLCHAIN_CONFIG = --enable-languages=c,c++ \
	$(GCC_CONFIG_FOR_TARGET) \
	$(COMMON_CONFIG) $(GCC_CONFIG) $(TOOLCHAIN_CONFIG) \
	--disable-werror \
	--target=$(TARGET) --prefix= \
	--libdir=/lib --disable-multilib \
	--with-sysroot=$(SYSROOT) \
	--enable-tls \
	--disable-libmudflap --disable-libsanitizer \
	--disable-gnu-indirect-function \
	--disable-libmpx \
	--enable-libstdcxx-time

FULL_MINGW_HEADERS_CONFIG = $(MINGW_CONFIG) \
	--prefix= --host=$(TARGET) --enable-sdk=all \
	--enable-idl --enable-secure-api

FULL_MINGW_CRT_CONFIG = $(MINGW_CONFIG) \
	--prefix= --host=$(TARGET) --with-sysroot=$(CURDIR)/obj_sysroot/$(TARGET)

FULL_MINGW_PTHREADS_CONFIG = $(MINGW_CONFIG) \
	--prefix= --host=$(TARGET) --with-sysroot=$(CURDIR)/obj_sysroot/$(TARGET)

ifeq ($(NATIVE),)
SYSROOT = /$(TARGET)
FULL_TOOLCHAIN_CONFIG += --with-build-sysroot=$(CURDIR)/obj_sysroot
FULL_MINGW_HEADERS_CONFIG += CC="$(XGCC)"
FULL_MINGW_CRT_CONFIG += CC="$(XGCC)" CPP="$(XCPP)" CPPFLAGS="-I$(CURDIR)/obj_sysroot/$(TARGET)/include" LDFLAGS="-L$(CURDIR)/obj_sysroot/$(TARGET)/lib"
FULL_MINGW_PTHREADS_CONFIG += CC="$(XGCC)" CPP="$(XCPP)" CPPFLAGS="-I$(CURDIR)/obj_sysroot/$(TARGET)/include" LDFLAGS="-L$(CURDIR)/obj_sysroot/$(TARGET)/lib"
MINGW_VARS = AR=$(XAR) RANLIB=$(XRANLIB)
obj_mingw_headers/.lc_configured: | obj_toolchain/binutils/.lc_built
obj_mingw_crt/.lc_configured: | obj_sysroot/.lc_headers obj_toolchain/gcc/.lc_built obj_toolchain/binutils/.lc_built obj_toolchain/gas/.lc_built
obj_mingw_pthreads/.lc_configured: | obj_sysroot/.lc_headers obj_toolchain/gcc/.lc_built obj_toolchain/binutils/.lc_built obj_toolchain/gas/.lc_built obj_sysroot/.lc_libs_crt
obj_toolchain/gcc/.lc_built: | obj_sysroot/usr obj_sysroot/lib64 obj_sysroot/include
obj_toolchain/.lc_built: | obj_sysroot/.lc_headers obj_sysroot/.lc_libs_crt
else
SYSROOT = /
FULL_TOOLCHAIN_CONFIG += --host=$(TARGET)
MINGW_VARS = 
endif

ifeq ($(TARGET),)

all:
	@echo TARGET must be set.
	@exit 1

install: all

else

all: mingw toolchain

install: install-mingw install-toolchain

mingw: obj_mingw_headers/.lc_built obj_mingw_crt/.lc_built obj_mingw_pthreads/.lc_built

toolchain: obj_toolchain/.lc_built

.PHONY: all mingw toolchain install-mingw install-toolchain clean

src_binutils: | $(BINUTILS_SRCDIR)
	ln -sf $(BINUTILS_SRCDIR) $@

src_gcc: | $(GCC_SRCDIR)
	ln -sf $(GCC_SRCDIR) $@

src_mingw: | $(MINGW_SRCDIR)
	ln -sf $(MINGW_SRCDIR) $@

ifneq ($(GMP_SRCDIR),)
src_toolchain: src_gmp
src_gmp: | $(GMP_SRCDIR)
	ln -sf "$(GMP_SRCDIR)" $@
endif

ifneq ($(MPC_SRCDIR),)
src_toolchain: src_mpc
src_mpc: | $(MPC_SRCDIR)
	ln -sf "$(MPC_SRCDIR)" $@
endif

ifneq ($(MPFR_SRCDIR),)
src_toolchain: src_mpfr
src_mpfr: | $(MPFR_SRCDIR)
	ln -sf "$(MPFR_SRCDIR)" $@
endif

ifneq ($(ISL_SRCDIR),)
src_toolchain: src_isl
src_isl: | $(ISL_SRCDIR)
	ln -sf "$(ISL_SRCDIR)" $@
endif

src_toolchain: src_binutils src_gcc
	rm -rf $@ $@.tmp
	mkdir $@.tmp
	cd $@.tmp && ln -sf ../src_binutils/* .
	cd $@.tmp && ln -sf ../src_gcc/* .
	$(if $(GMP_SRCDIR),cd $@.tmp && ln -sf ../src_gmp gmp)
	$(if $(MPC_SRCDIR),cd $@.tmp && ln -sf ../src_mpc mpc)
	$(if $(MPFR_SRCDIR),cd $@.tmp && ln -sf ../src_mpfr mpfr)
	$(if $(ISL_SRCDIR),cd $@.tmp && ln -sf ../src_isl isl)
	mv $@.tmp $@

obj_%:
	mkdir -p $@

obj_sysroot/include:
	mkdir -p $@

obj_sysroot/usr: | obj_sysroot
	ln -sf . $@

obj_sysroot/lib64: | obj_sysroot
	ln -sf lib $@

obj_toolchain/.lc_configured: | obj_toolchain src_toolchain
	cd obj_toolchain && ../src_toolchain/configure $(FULL_TOOLCHAIN_CONFIG)
	touch $@

obj_toolchain/gas/.lc_built: | obj_toolchain/.lc_configured
	cd obj_toolchain && $(MAKE) MAKE="$(MAKE)" all-gas
	touch $@

obj_toolchain/binutils/.lc_built: | obj_toolchain/.lc_configured
	cd obj_toolchain && $(MAKE) MAKE="$(MAKE)" all-binutils
	touch $@

obj_toolchain/gcc/.lc_built: | obj_sysroot/.lc_headers obj_toolchain/.lc_configured
	cd obj_toolchain && $(MAKE) MAKE="$(MAKE)" all-gcc
	touch $@

obj_mingw_headers/.lc_configured: | obj_mingw_headers src_mingw
	cd obj_mingw_headers && ../src_mingw/mingw-w64-headers/configure $(FULL_MINGW_HEADERS_CONFIG)
	touch $@

obj_mingw_headers/.lc_built: | obj_mingw_headers/.lc_configured
	cd obj_mingw_headers && $(MAKE) $(MINGW_VARS)
	touch $@

obj_sysroot/.lc_headers: | obj_mingw_headers/.lc_configured obj_sysroot
	cd obj_mingw_headers && $(MAKE) DESTDIR=$(CURDIR)/obj_sysroot/$(TARGET) install
	ln -sf $(TARGET) $(CURDIR)/obj_sysroot/mingw
	touch $@

obj_mingw_crt/.lc_configured: | obj_sysroot/.lc_headers obj_toolchain/binutils/.lc_built obj_toolchain/gas/.lc_built obj_toolchain/gcc/.lc_built obj_mingw_crt src_mingw
	cd obj_mingw_crt && ../src_mingw/mingw-w64-crt/configure $(FULL_MINGW_CRT_CONFIG)
	touch $@

obj_mingw_crt/.lc_built: | obj_mingw_crt/.lc_configured
	cd obj_mingw_crt && $(MAKE) $(MINGW_VARS)
	touch $@

obj_mingw_pthreads/.lc_configured: | obj_mingw_crt/.lc_built obj_mingw_pthreads src_mingw
	cd obj_mingw_pthreads && ../src_mingw/mingw-w64-libraries/winpthreads/configure $(FULL_MINGW_PTHREADS_CONFIG)
	touch $@

obj_mingw_pthreads/.lc_built: | obj_mingw_pthreads/.lc_configured
	cd obj_mingw_pthreads && $(MAKE) $(MINGW_VARS)
	touch $@

obj_sysroot/.lc_libs_pthreads: | obj_mingw_pthreads/.lc_built
	cd obj_mingw_pthreads && $(MAKE) $(MINGW_VARS) DESTDIR=$(CURDIR)/obj_sysroot/$(TARGET) install
	touch $@

obj_sysroot/.lc_libs_crt: | obj_mingw_crt/.lc_built
	cd obj_mingw_crt && $(MAKE) $(MINGW_VARS) DESTDIR=$(CURDIR)/obj_sysroot/$(TARGET) install
	touch $@

obj_toolchain/.lc_built: | obj_toolchain/.lc_configured obj_sysroot/.lc_headers obj_sysroot/.lc_libs_crt
	cd obj_toolchain && $(MAKE) MAKE="$(MAKE)"
	touch $@
install-mingw-headers: | obj_mingw_headers/.lc_configured
	cd obj_mingw_headers && $(MAKE) $(MINGW_VARS) DESTDIR=$(DESTDIR)$(OUTPUT)$(SYSROOT) install

install-mingw-crt: | obj_mingw_crt/.lc_built
	cd obj_mingw_crt && $(MAKE) $(MINGW_VARS) DESTDIR=$(DESTDIR)$(OUTPUT)$(SYSROOT) install

install-mingw-pthreads: | obj_mingw_pthreads/.lc_built
	cd obj_mingw_pthreads && $(MAKE) $(MINGW_VARS) DESTDIR=$(DESTDIR)$(OUTPUT)$(SYSROOT) install

install-mingw: install-mingw-headers install-mingw-crt install-mingw-pthreads

install-toolchain: | obj_mingw_crt/.lc_configured obj_toolchain/.lc_built
	cd obj_toolchain && $(MAKE) MAKE="$(MAKE)" DESTDIR=$(DESTDIR)$(OUTPUT) install
	ln -sf $(TARGET)-gcc $(DESTDIR)$(OUTPUT)/bin/$(TARGET)-cc


endif

clean:
	rm -rf src_* obj_*
