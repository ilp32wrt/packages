# SPDX-License-Identifier: GPL-2.0-only
#
# Included by lang/rust/rust-values.mk for every package except lang/rust itself. It lives outside
# lang/rust because that whole directory is in rust's prepare hash (any change there rebuilds rust).

RUST_ILP32_DIR:=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))/

# AArch64 ILP32: crates.io's libc has no AArch64 ILP32 port, cpufeatures assumes a 64-bit c_ulong,
# target-lexicon does not know the musl_ilp32 environment (pyo3-build-config), and pnet_sys assumes
# that tv_usec is a c_long.
# lang/rust installs fixed crates; cargo packages use them through [patch.crates-io]:
# - rust-package.mk passes RUST_ILP32_CARGO_ARGS (cargo install --path does not read the package's
#   .cargo/config.toml);
# - after prepare, every target package that includes this file (also CMake and maturin builds) gets
#   $(PKG_BUILD_DIR)/.cargo/config.toml, and its Cargo.lock files are moved to the patched crates, so
#   that --locked holds. Not in $(BUILD_DIR) itself: rust's own host build (--frozen) is below it.
ifndef RUST_ILP32_MK_INCLUDED
RUST_ILP32_MK_INCLUDED:=1
ifeq ($(CONFIG_AARCH64_ABI_ILP32),y)
  RUST_ILP32_CRATES:=$(STAGING_DIR)/host/share/rust-ilp32
  RUST_ILP32_CARGO_ARGS:= \
	--config 'patch.crates-io.libc.path="$(RUST_ILP32_CRATES)/libc-0.2.191"' \
	--config 'patch.crates-io.cpufeatures.path="$(RUST_ILP32_CRATES)/cpufeatures-0.2.17"' \
	--config 'patch.crates-io.cpufeatures03.path="$(RUST_ILP32_CRATES)/cpufeatures-0.3.1"' \
	--config 'patch.crates-io.cpufeatures03.package="cpufeatures"' \
	--config 'patch.crates-io.target-lexicon.path="$(RUST_ILP32_CRATES)/target-lexicon-0.13.5"' \
	--config 'patch.crates-io.target-lexicon012.path="$(RUST_ILP32_CRATES)/target-lexicon-0.12.16"' \
	--config 'patch.crates-io.target-lexicon012.package="target-lexicon"' \
	--config 'patch.crates-io.pnet_sys.path="$(RUST_ILP32_CRATES)/pnet_sys-0.33.0"'

  # moves Cargo.lock to the fixed crates; fails if a crates.io copy of one stays (see the script)
  # PATH: cargo asks rustc for its version; the staging rustc is not in PATH during prepare
  RUST_ILP32_LOCK = PATH=$(STAGING_DIR)/host/bin:$$$$PATH CARGO_HOME=$(CARGO_HOME) \
	$(RUST_ILP32_DIR)ilp32-cargo-lock.sh $(1) $(2)

  define RustIlp32/CargoPatch
	if [ -d $(RUST_ILP32_CRATES)/libc-0.2.191 ]; then \
		mkdir -p $(PKG_BUILD_DIR)/.cargo && \
		printf '[patch.crates-io]\nlibc = { path = "%s/libc-0.2.191" }\ncpufeatures = { path = "%s/cpufeatures-0.2.17" }\ncpufeatures03 = { path = "%s/cpufeatures-0.3.1", package = "cpufeatures" }\ntarget-lexicon = { path = "%s/target-lexicon-0.13.5" }\ntarget-lexicon012 = { path = "%s/target-lexicon-0.12.16", package = "target-lexicon" }\npnet_sys = { path = "%s/pnet_sys-0.33.0" }\n' \
			'$(RUST_ILP32_CRATES)' '$(RUST_ILP32_CRATES)' '$(RUST_ILP32_CRATES)' '$(RUST_ILP32_CRATES)' '$(RUST_ILP32_CRATES)' '$(RUST_ILP32_CRATES)' \
			> $(PKG_BUILD_DIR)/.cargo/config.toml && \
		$(call RUST_ILP32_LOCK,$(PKG_BUILD_DIR),libc@0.2.191 cpufeatures@0.2.17 cpufeatures@0.3.1 target-lexicon@0.13.5 target-lexicon@0.12.16 pnet_sys@0.33.0); \
	fi
  endef

  # host tools that run for the ILP32 target (maturin) must parse its triple: target-lexicon only
  define RustIlp32/HostCargoPatch
	if [ -d $(RUST_ILP32_CRATES)/target-lexicon-0.13.5 ]; then \
		mkdir -p $(HOST_BUILD_DIR)/.cargo && \
		printf '[patch.crates-io]\ntarget-lexicon = { path = "%s/target-lexicon-0.13.5" }\ntarget-lexicon012 = { path = "%s/target-lexicon-0.12.16", package = "target-lexicon" }\n' \
			'$(RUST_ILP32_CRATES)' '$(RUST_ILP32_CRATES)' > $(HOST_BUILD_DIR)/.cargo/config.toml && \
		$(call RUST_ILP32_LOCK,$(HOST_BUILD_DIR),target-lexicon@0.13.5 target-lexicon@0.12.16); \
	fi
  endef

  Hooks/Prepare/Post += RustIlp32/CargoPatch
  Hooks/HostPrepare/Post += RustIlp32/HostCargoPatch
endif
endif
