# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2023 Luca Barbato and Donald Hoskins

include $(TOPDIR)/rules.mk

PKG_NAME:=rust
PKG_VERSION:=1.96.0
PKG_RELEASE:=4

PKG_SOURCE:=rustc-$(PKG_VERSION)-src.tar.xz
PKG_SOURCE_URL:=https://static.rust-lang.org/dist/
PKG_HASH:=b99ce16cdf0ecfc761b585ac84d131b46733465a02f8ecd0ff2de9713c62ee09
HOST_BUILD_DIR:=$(BUILD_DIR)/host/rustc-$(PKG_VERSION)-src

PKG_MAINTAINER:=Luca Barbato <lu_zero@luminem.org>
PKG_LICENSE:=Apache-2.0 MIT
PKG_LICENSE_FILES:=LICENSE-APACHE LICENSE-MIT
PKG_CPE_ID:=cpe:/a:rust-lang:rust

PKG_HOST_ONLY:=1
PKG_BUILD_FLAGS:=no-mips16

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/package.mk
include ./rust-values.mk

# Crates with the AArch64 ILP32 port: the crates.io release plus crate-patches/<crate>-<version>/,
# applied in Host/Prepare and installed to $(STAGING_DIR)/host/share/rust-ilp32 for cargo packages
# ([patch.crates-io], lang/rust-ilp32/rust-ilp32.mk). std uses libc (patches/0103 locks it).
#   libc: AArch64 ILP32 glibc/musl port
#   cpufeatures: assumes a 64-bit c_ulong on aarch64 (getauxval)
#   target-lexicon (pyo3-build-config etc.): does not know the musl_ilp32 environment
RUST_ILP32_LIBC_VERSION:=0.2.191
RUST_ILP32_LIBC_HASH:=65cd87c9a6d60536580b316ad985726104730a5151c99845f2490428ef91240a
RUST_ILP32_CRATE_LIST:=

define Download/libc-0.2.191
  FILE:=libc-0.2.191.crate
  URL:=https://static.crates.io/crates/libc
  HASH:=65cd87c9a6d60536580b316ad985726104730a5151c99845f2490428ef91240a
endef
$(eval $(call Download,libc-0.2.191))
RUST_ILP32_CRATE_LIST+=libc-0.2.191

define Download/cpufeatures-0.2.17
  FILE:=cpufeatures-0.2.17.crate
  URL:=https://static.crates.io/crates/cpufeatures
  HASH:=59ed5838eebb26a2bb2e58f6d5b5316989ae9d08bab10e0e6d103e656d1b0280
endef
$(eval $(call Download,cpufeatures-0.2.17))
RUST_ILP32_CRATE_LIST+=cpufeatures-0.2.17

define Download/cpufeatures-0.3.1
  FILE:=cpufeatures-0.3.1.crate
  URL:=https://static.crates.io/crates/cpufeatures
  HASH:=5ca28b0ae3115b884660db4118d803791fd6756b6e88f39c0f3f7859060d7566
endef
$(eval $(call Download,cpufeatures-0.3.1))
RUST_ILP32_CRATE_LIST+=cpufeatures-0.3.1

define Download/target-lexicon-0.13.5
  FILE:=target-lexicon-0.13.5.crate
  URL:=https://static.crates.io/crates/target-lexicon
  HASH:=adb6935a6f5c20170eeceb1a3835a49e12e19d792f6dd344ccc76a985ca5a6ca
endef
$(eval $(call Download,target-lexicon-0.13.5))
RUST_ILP32_CRATE_LIST+=target-lexicon-0.13.5

define Download/target-lexicon-0.12.16
  FILE:=target-lexicon-0.12.16.crate
  URL:=https://static.crates.io/crates/target-lexicon
  HASH:=61c41af27dd6d1e27b1b16b489db798443478cef1f06a660c96db617ba5de3b1
endef
$(eval $(call Download,target-lexicon-0.12.16))
RUST_ILP32_CRATE_LIST+=target-lexicon-0.12.16

define Package/rust
  SECTION:=lang
  CATEGORY:=Languages
  SUBMENU:=Rust
  TITLE:=Rust Programming Language Compiler
  URL:=https://www.rust-lang.org/
  DEPENDS:=$(RUST_ARCH_DEPENDS)
endef

define Package/rust/description
  Rust is a multi-paradigm, general-purpose programming language designed for performance
  and safety, especially safe concurrency. Rust is syntactically similar to C++, but can
  guarantee memory safety by using a borrow checker to validate references.
endef

define Package/rust/config
  source "$(SOURCE)/Config.in"
endef

# Rust-lang has an uninstall script
RUST_UNINSTALL:=$(STAGING_DIR)/host/lib/rustlib/uninstall.sh

# Target Flags
TARGET_CONFIGURE_ARGS = \
	--set=target.$(RUSTC_TARGET_ARCH).ar=$(TARGET_AR) \
	--set=target.$(RUSTC_TARGET_ARCH).cc=$(TARGET_CC_NOCACHE) \
	--set=target.$(RUSTC_TARGET_ARCH).cxx=$(TARGET_CXX_NOCACHE) \
	--set=target.$(RUSTC_TARGET_ARCH).linker=$(TARGET_CC_NOCACHE) \
	--set=target.$(RUSTC_TARGET_ARCH).ranlib=$(TARGET_RANLIB) \
	--set=target.$(RUSTC_TARGET_ARCH).crt-static=false \
	$(if $(CONFIG_USE_MUSL),--set=target.$(RUSTC_TARGET_ARCH).musl-root=$(TOOLCHAIN_ROOT_DIR))

# CARGO_HOME is an environmental
HOST_CONFIGURE_VARS += CARGO_HOME="$(CARGO_HOME)"

# Rust Configuration Arguments
HOST_CONFIGURE_ARGS = \
	--build=$(RUSTC_HOST_ARCH) \
	--target=$(RUSTC_TARGET_ARCH),$(RUSTC_HOST_ARCH) \
	--host=$(RUSTC_HOST_ARCH) \
	--prefix=$(STAGING_DIR)/host \
	--bindir=$(STAGING_DIR)/host/bin \
	--libdir=$(STAGING_DIR)/host/lib \
	--sysconfdir=$(STAGING_DIR)/host/etc \
	--datadir=$(STAGING_DIR)/host/share \
	--mandir=$(STAGING_DIR)/host/man \
	--dist-compression-formats=gz \
	--disable-sanitizers \
	--release-channel=stable \
	--enable-cargo-native-static \
	--bootstrap-cache-path=$(DL_DIR)/rustc \
	--set=llvm.download-ci-llvm=false \
	$(TARGET_CONFIGURE_ARGS)

define Host/Prepare
	$(call Host/Prepare/Default)
	rm -rf $(HOST_BUILD_DIR)/ilp32-crates
	mkdir -p $(HOST_BUILD_DIR)/ilp32-crates
	for c in $(RUST_ILP32_CRATE_LIST); do \
		tar -xzf $(DL_DIR)/$$$$c.crate -C $(HOST_BUILD_DIR)/ilp32-crates || exit 1; \
		rm -f $(HOST_BUILD_DIR)/ilp32-crates/$$$$c/.cargo_vcs_info.json; \
		for p in $(CURDIR)/crate-patches/$$$$c/*.patch; do \
			$(PATCH) -d $(HOST_BUILD_DIR)/ilp32-crates/$$$$c -p1 -E --forward --no-backup-if-mismatch \
				-i $$$$p || exit 1; \
		done; \
	done
	# vendored for std; "files":{} skips the per-file checksums of the patched sources
	rm -rf $(HOST_BUILD_DIR)/vendor/libc-$(RUST_ILP32_LIBC_VERSION)
	$(CP) $(HOST_BUILD_DIR)/ilp32-crates/libc-$(RUST_ILP32_LIBC_VERSION) $(HOST_BUILD_DIR)/vendor/
	printf '{"files":{},"package":"%s"}' $(RUST_ILP32_LIBC_HASH) \
		> $(HOST_BUILD_DIR)/vendor/libc-$(RUST_ILP32_LIBC_VERSION)/.cargo-checksum.json
endef

define Host/Uninstall
	# Call the Uninstall script
	[ -f $(RUST_UNINSTALL) ] && \
		$(BASH) $(RUST_UNINSTALL) || echo No Uninstall
endef

define Host/Compile
	$(RUST_SCCACHE_VARS) \
	CARGO_HOME=$(CARGO_HOME) \
	TARGET_CFLAGS="$(TARGET_CFLAGS)" \
	$(if $(RUSTC_TARGET_RUSTFLAGS),$(RUSTC_TARGET_CARGO_RUSTFLAGS)="$(RUSTC_TARGET_RUSTFLAGS)") \
	$(PYTHON) $(HOST_BUILD_DIR)/x.py \
		--build-dir $(HOST_BUILD_DIR)/build \
		dist build-manifest rustc rust-std cargo llvm-tools rust-src
endef

define Host/Install
	( \
		cd $(HOST_BUILD_DIR)/build/dist ; \
		for targz in *.tar.gz; do \
			$(STAGING_DIR_HOST)/bin/libdeflate-gzip -dc "$$$$targz" | tar -xf - ; \
		done ; \
		find . -mindepth 2 -maxdepth 2 -type f -name install.sh \
			-execdir bash '{}' --prefix=$(STAGING_DIR)/host --disable-ldconfig \; ; \
	)
	rm -rf $(STAGING_DIR)/host/share/rust-ilp32
	$(INSTALL_DIR) $(STAGING_DIR)/host/share/rust-ilp32
	$(CP) $(HOST_BUILD_DIR)/ilp32-crates/* $(STAGING_DIR)/host/share/rust-ilp32/
endef

$(eval $(call HostBuild))
$(eval $(call BuildPackage,rust))
