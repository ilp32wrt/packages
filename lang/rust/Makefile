# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2023 Luca Barbato and Donald Hoskins

include $(TOPDIR)/rules.mk

PKG_NAME:=rust
PKG_VERSION:=1.96.0
PKG_RELEASE:=3

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

# std uses libc 0.2.191 with the AArch64 ILP32 glibc/musl port (patches/0103 locks it); the same
# crate is installed for cargo packages ([patch.crates-io] in rust-package.mk)
RUST_ILP32_LIBC_VERSION:=0.2.191
RUST_ILP32_LIBC_CRATE:=libc-$(RUST_ILP32_LIBC_VERSION)-ilp32.crate
RUST_ILP32_LIBC_HASH:=df0684e089db1c9c721fe133d8c5ce4e14b26c2c6d28d81a09c10c4554266566

define Download/libc-ilp32
  FILE:=$(RUST_ILP32_LIBC_CRATE)
  # not published yet: put the file into dl/ for now
  URL:=https://github.com/ilp32wrt/packages/releases/download/rust-libc-$(RUST_ILP32_LIBC_VERSION)-ilp32
  HASH:=$(RUST_ILP32_LIBC_HASH)
endef
$(eval $(call Download,libc-ilp32))

# cpufeatures assumes 64-bit c_ulong on aarch64 (getauxval); fixed copies of the 0.2 and 0.3 series
RUST_ILP32_CPUFEATURES02:=0.2.17
RUST_ILP32_CPUFEATURES03:=0.3.1

define Download/cpufeatures02-ilp32
  FILE:=cpufeatures-$(RUST_ILP32_CPUFEATURES02)-ilp32.crate
  URL:=https://github.com/ilp32wrt/packages/releases/download/rust-libc-$(RUST_ILP32_LIBC_VERSION)-ilp32
  HASH:=9767c7f60c1a5481570005c6f18a13a28832d3c705135d160a34ef0c4de58072
endef
$(eval $(call Download,cpufeatures02-ilp32))

define Download/cpufeatures03-ilp32
  FILE:=cpufeatures-$(RUST_ILP32_CPUFEATURES03)-ilp32.crate
  URL:=https://github.com/ilp32wrt/packages/releases/download/rust-libc-$(RUST_ILP32_LIBC_VERSION)-ilp32
  HASH:=f33177d415b010ce507a9aed384cc595b088711722b96d901a62b9bd5af85314
endef
$(eval $(call Download,cpufeatures03-ilp32))

# target-lexicon (pyo3-build-config etc.) does not know the musl_ilp32 environment
RUST_ILP32_TARGET_LEXICON013:=0.13.5
RUST_ILP32_TARGET_LEXICON012:=0.12.16

define Download/target-lexicon013-ilp32
  FILE:=target-lexicon-$(RUST_ILP32_TARGET_LEXICON013)-ilp32.crate
  URL:=https://github.com/ilp32wrt/packages/releases/download/rust-libc-$(RUST_ILP32_LIBC_VERSION)-ilp32
  HASH:=fb6f5f991ed9671be9cfb520873f6742f38f62773f1dea10d03109baace7eb56
endef
$(eval $(call Download,target-lexicon013-ilp32))

define Download/target-lexicon012-ilp32
  FILE:=target-lexicon-$(RUST_ILP32_TARGET_LEXICON012)-ilp32.crate
  URL:=https://github.com/ilp32wrt/packages/releases/download/rust-libc-$(RUST_ILP32_LIBC_VERSION)-ilp32
  HASH:=b7abe3471d6cba0e2a4bb18e0b0657a27a64058063cb3c6f60e426f60e3371fe
endef
$(eval $(call Download,target-lexicon012-ilp32))

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
	tar -xzf $(DL_DIR)/$(RUST_ILP32_LIBC_CRATE) -C $(HOST_BUILD_DIR)/vendor
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
	$(INSTALL_DIR) $(STAGING_DIR)/host/share/rust-ilp32
	rm -rf $(STAGING_DIR)/host/share/rust-ilp32/libc-$(RUST_ILP32_LIBC_VERSION)
	$(CP) $(HOST_BUILD_DIR)/vendor/libc-$(RUST_ILP32_LIBC_VERSION) $(STAGING_DIR)/host/share/rust-ilp32/
	rm -rf $(STAGING_DIR)/host/share/rust-ilp32/cpufeatures-*
	tar -xzf $(DL_DIR)/cpufeatures-$(RUST_ILP32_CPUFEATURES02)-ilp32.crate -C $(STAGING_DIR)/host/share/rust-ilp32
	tar -xzf $(DL_DIR)/cpufeatures-$(RUST_ILP32_CPUFEATURES03)-ilp32.crate -C $(STAGING_DIR)/host/share/rust-ilp32
	rm -rf $(STAGING_DIR)/host/share/rust-ilp32/target-lexicon-*
	tar -xzf $(DL_DIR)/target-lexicon-$(RUST_ILP32_TARGET_LEXICON013)-ilp32.crate -C $(STAGING_DIR)/host/share/rust-ilp32
	tar -xzf $(DL_DIR)/target-lexicon-$(RUST_ILP32_TARGET_LEXICON012)-ilp32.crate -C $(STAGING_DIR)/host/share/rust-ilp32
endef

$(eval $(call HostBuild))
$(eval $(call BuildPackage,rust))
