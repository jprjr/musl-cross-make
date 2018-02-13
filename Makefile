
SOURCES = sources

CONFIG_SUB_REV = 3d5db9ebe860
BINUTILS_VER = 2.28.1
GCC_VER = 7.2.0
GMP_VER = 6.1.2
MPC_VER = 1.0.3
MPFR_VER = 4.0.0
ZLIB_VER = 1.2.11
MINGW_VER = v5.0.3


GNU_SITE = https://ftp.gnu.org/pub/gnu
GCC_SITE = $(GNU_SITE)/gcc
BINUTILS_SITE = $(GNU_SITE)/binutils
GMP_SITE = $(GNU_SITE)/gmp
MPC_SITE = $(GNU_SITE)/mpc
MPFR_SITE = $(GNU_SITE)/mpfr
ISL_SITE = http://isl.gforge.inria.fr/
ZLIB_SITE = https://www.zlib.net/

MINGW_SITE = https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/




DL_CMD = curl -R -L -o

ifneq ($(NATIVE),)
HOST := $(TARGET)
endif

ifneq ($(HOST),)
BUILD_DIR = build/$(HOST)/$(TARGET)
OUTPUT = $(CURDIR)/output-$(HOST)
else
BUILD_DIR = build/local/$(TARGET)
OUTPUT = $(CURDIR)/output
endif

REL_TOP = ../../..

-include config.mak

SRC_DIRS = gcc-$(GCC_VER) binutils-$(BINUTILS_VER) mingw-w64-$(MINGW_VER) \
	$(if $(ZLIB_VER),zlib-$(ZLIB_VER)) \
	$(if $(GMP_VER),gmp-$(GMP_VER)) \
	$(if $(MPC_VER),mpc-$(MPC_VER)) \
	$(if $(MPFR_VER),mpfr-$(MPFR_VER)) \
	$(if $(ISL_VER),isl-$(ISL_VER)) \
	$(if $(LINUX_VER),linux-$(LINUX_VER))

all:

clean:
	rm -rf gcc-* binutils-* mingw-w64-* gmp-* mpc-* mpfr-* isl-* build-* build zlib-*

distclean: clean
	rm -rf sources


# Rules for downloading and verifying sources. Treat an external SOURCES path as
# immutable and do not try to download anything into it.

ifeq ($(SOURCES),sources)

$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/zlib*)): SITE = $(ZLIB_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/gmp*)): SITE = $(GMP_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/mpc*)): SITE = $(MPC_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/mpfr*)): SITE = $(MPFR_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/isl*)): SITE = $(ISL_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/binutils*)): SITE = $(BINUTILS_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/gcc*)): SITE = $(GCC_SITE)/$(basename $(basename $(notdir $@)))
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/mingw-w64*)): SITE = $(MINGW_SITE)





$(SOURCES):
	mkdir -p $@

$(SOURCES)/config.sub: | $(SOURCES)
	mkdir -p $@.tmp
	cd $@.tmp && $(DL_CMD) $(notdir $@) "http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=$(CONFIG_SUB_REV)"
	cd $@.tmp && touch $(notdir $@)
	cd $@.tmp && sha1sum -c $(CURDIR)/hashes/$(notdir $@).$(CONFIG_SUB_REV).sha1
	mv $@.tmp/$(notdir $@) $@
	rm -rf $@.tmp

$(SOURCES)/%: hashes/%.sha1 | $(SOURCES)
	mkdir -p $@.tmp
	cd $@.tmp && $(DL_CMD) $(notdir $@) $(SITE)/$(notdir $@)
	cd $@.tmp && touch $(notdir $@)
	cd $@.tmp && sha1sum -c $(CURDIR)/hashes/$(notdir $@).sha1
	mv $@.tmp/$(notdir $@) $@
	rm -rf $@.tmp

endif


# Rules for extracting and patching sources, or checking them out from git.

%: $(SOURCES)/%.tar.gz | $(SOURCES)/config.sub
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && tar zxvf - ) < $<
	test ! -d patches/$@ || cat patches/$@/* | ( cd $@.tmp/$@ && patch -p1 )
	test ! -f $@.tmp/$@/config.sub || cp -f $(SOURCES)/config.sub $@.tmp/$@
	rm -rf $@
	touch $@.tmp/$@
	mv $@.tmp/$@ $@
	rm -rf $@.tmp

%: $(SOURCES)/%.tar.bz2 | $(SOURCES)/config.sub
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && tar jxvf - ) < $<
	test ! -d patches/$@ || cat patches/$@/* | ( cd $@.tmp/$@ && patch -p1 )
	test ! -f $@.tmp/$@/config.sub || cp -f $(SOURCES)/config.sub $@.tmp/$@
	rm -rf $@
	touch $@.tmp/$@
	mv $@.tmp/$@ $@
	rm -rf $@.tmp

%: $(SOURCES)/%.tar.xz | $(SOURCES)/config.sub
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && tar Jxvf - ) < $<
	test ! -d patches/$@ || cat patches/$@/* | ( cd $@.tmp/$@ && patch -p1 )
	test ! -f $@.tmp/$@/config.sub || cp -f $(SOURCES)/config.sub $@.tmp/$@
	rm -rf $@
	touch $@.tmp/$@
	mv $@.tmp/$@ $@
	rm -rf $@.tmp

extract_all: | $(SRC_DIRS)


# Rules for building.

ifeq ($(TARGET),)

all:
	@echo TARGET must be set via config.mak or command line.
	@exit 1

else

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/Makefile: | $(BUILD_DIR)
	ln -sf $(REL_TOP)/litecross/Makefile $@

$(BUILD_DIR)/config.mak: | $(BUILD_DIR)
	printf >$@ '%s\n' \
	"TARGET = $(TARGET)" \
	"HOST = $(HOST)" \
	"MINGW_SRCDIR = $(REL_TOP)/mingw-w64-$(MINGW_VER)" \
	"GCC_SRCDIR = $(REL_TOP)/gcc-$(GCC_VER)" \
	"BINUTILS_SRCDIR = $(REL_TOP)/binutils-$(BINUTILS_VER)" \
	$(if $(ZLIB_VER),"ZLIB_SRCDIR = $(REL_TOP)/zlib-$(ZLIB_VER)") \
	$(if $(GMP_VER),"GMP_SRCDIR = $(REL_TOP)/gmp-$(GMP_VER)") \
	$(if $(MPC_VER),"MPC_SRCDIR = $(REL_TOP)/mpc-$(MPC_VER)") \
	$(if $(MPFR_VER),"MPFR_SRCDIR = $(REL_TOP)/mpfr-$(MPFR_VER)") \
	$(if $(ISL_VER),"ISL_SRCDIR = $(REL_TOP)/isl-$(ISL_VER)") \
	$(if $(LINUX_VER),"LINUX_SRCDIR = $(REL_TOP)/linux-$(LINUX_VER)") \
	"-include $(REL_TOP)/config.mak"

all: | $(SRC_DIRS) $(BUILD_DIR) $(BUILD_DIR)/Makefile $(BUILD_DIR)/config.mak
	cd $(BUILD_DIR) && $(MAKE) $@

$(BUILD_DIR)/obj_toolchain/binutils/.lc_built: $(SRC_DIRS) $(BUILD_DIR) $(BUILD_DIR)/Makefile $(BUILD_DIR)/config.mak
	cd $(BUILD_DIR) && $(MAKE) obj_toolchain/binutils/.lc_built

$(BUILD_DIR)/obj_toolchain/gas/.lc_built: $(SRC_DIRS) $(BUILD_DIR) $(BUILD_DIR)/Makefile $(BUILD_DIR)/config.mak $(BUILD_DIR)/obj_toolchain/binutils/.lc_built
	cd $(BUILD_DIR) && $(MAKE) obj_toolchain/gas/.lc_built

$(BUILD_DIR)/obj_toolchain/gcc/.lc_built: $(SRC_DIRS) $(BUILD_DIR) $(BUILD_DIR)/Makefile $(BUILD_DIR)/config.mak $(BUILD_DIR)/obj_toolchain/gas/.lc_built
	cd $(BUILD_DIR) && $(MAKE) obj_toolchain/gcc/.lc_built

binutils: | $(BUILD_DIR)/obj_toolchain/binutils/.lc_built

gas: | $(BUILD_DIR)/obj_toolchain/gas/.lc_built

gcc: | $(BUILD_DIR)/obj_toolchain/gcc/.lc_built

install: | $(SRC_DIRS) $(BUILD_DIR) $(BUILD_DIR)/Makefile $(BUILD_DIR)/config.mak
	cd $(BUILD_DIR) && $(MAKE) OUTPUT=$(OUTPUT) $@

endif
