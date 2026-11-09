# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2023 Luca Barbato and Donald Hoskins

# Variables (all optional) to be set in package Makefiles:
#
# RUST_PKG_FEATURES - list of options, default empty
#
#   Space or comma separated list of features to activate
#
#   e.g. RUST_PKG_FEATURES:=enable-foo,with-bar
#
#
# RUST_PKG_LOCKED - Assert that `Cargo.lock` will remain unchanged
#                   (Enabled by default)
#
#   Disable it if you want to have up-to-date dependencies
#
#   e.g. RUST_PKG_LOCKED:=0


ifeq ($(origin RUST_INCLUDE_DIR),undefined)
  RUST_INCLUDE_DIR:=$(dir $(lastword $(MAKEFILE_LIST)))
endif
include $(RUST_INCLUDE_DIR)/rust-values.mk

RUST_PKG_LOCKED ?= 1

CARGO_PKG_VARS= \
	$(CARGO_PKG_CONFIG_VARS) \
	CC=$(HOSTCC_NOCACHE) \
	MAKEFLAGS="$(PKG_JOBS)"

CARGO_PKG_ARGS=

ifeq ($(strip $(RUST_PKG_LOCKED)),1)
  CARGO_PKG_ARGS+= --locked
endif

# AArch64 ILP32: the libc crate with the ILP32 port (installed by lang/rust) replaces crates.io's,
# and Cargo.lock is moved to it first (requirements up to ^0.2.191 are met)
RUST_ILP32_LIBC_DIR:=$(STAGING_DIR)/host/share/rust-ilp32/libc-0.2.191
ifeq ($(CONFIG_AARCH64_ABI_ILP32),y)
  CARGO_ILP32_PATCH:=--config 'patch.crates-io.libc.path="$(RUST_ILP32_LIBC_DIR)"'
  CARGO_PKG_ARGS+= $(CARGO_ILP32_PATCH)
endif

# $(1) path to the package (optional)
# $(2) additional arguments to cargo (optional)
define Build/Compile/Cargo
	$(if $(CARGO_ILP32_PATCH),+$(CARGO_PKG_VARS) cargo update $(CARGO_ILP32_PATCH) \
		--manifest-path "$(PKG_BUILD_DIR)/$(if $(strip $(1)),$(strip $(1)),$(strip $(MAKE_PATH)))/Cargo.toml" \
		-p libc || true)
	+$(CARGO_PKG_VARS) \
	cargo install -v \
		--profile $(CARGO_PKG_PROFILE) \
		$(if $(strip $(RUST_PKG_FEATURES)),--features "$(strip $(RUST_PKG_FEATURES))") \
		--root $(PKG_INSTALL_DIR) \
		--path "$(PKG_BUILD_DIR)/$(if $(strip $(1)),$(strip $(1)),$(strip $(MAKE_PATH)))" \
		$(if $(filter --jobserver%,$(PKG_JOBS)),,-j1) \
		$(CARGO_PKG_ARGS) \
		$(2)
endef

define RustBinPackage
  ifndef Package/$(1)/install
    define Package/$(1)/install
	$$(INSTALL_DIR) $$(1)/usr/bin/
	$$(INSTALL_BIN) $$(PKG_INSTALL_DIR)/bin/* $$(1)/usr/bin/
    endef
  endif
endef

Build/Compile=$(call Build/Compile/Cargo)
