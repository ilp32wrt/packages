#!/bin/sh
# AArch64 ILP32: move every Cargo.lock below <dir> to the fixed crates of lang/rust ([patch.crates-io]
# in <dir>/.cargo/config.toml) and fail if a crates.io copy of a patched crate stays in the graph.
#
# Usage: ilp32-cargo-lock.sh <dir> <crate>@<patched version>...
#   e.g. ilp32-cargo-lock.sh build/foo libc@0.2.191 cpufeatures@0.2.17 cpufeatures@0.3.1
# Needs cargo (and rustc) in PATH. A crate is matched by series: 0.2.x for 0.2.17, 1.x for 1.y.
# When a crate cannot move because another package pins it (nix 0.31.1 pins libc =0.2.180),
# that package is updated together with it (cargo names it in "required by package `X vY`").
set -u
dir=$1; shift
log=$dir/.cargo/ilp32-update.log
mkdir -p "$dir/.cargo"
status=0

series() { # 0.2.17 -> 0.2 ; 1.4.0 -> 1
	case $1 in 0.*) echo "$1" | cut -d. -f1,2 ;; *) echo "$1" | cut -d. -f1 ;; esac
}

# versions of crate $2 in lock $1 that come from a registry (not the path patch)
registry_versions() {
	# every table header ends the previous entry; only [[package]] entries count
	# ([[patch.unused]] has name/version but no source)
	awk -v want="$2" '
		function flush() { if (pkg && n == want && src ~ /^registry/) print v; n = ""; v = ""; src = "" }
		/^\[/ { flush(); pkg = ($0 ~ /^\[\[package\]\]/); next }
		/^name = /    { gsub(/"/, "", $3); n = $3 }
		/^version = / { gsub(/"/, "", $3); v = $3 }
		/^source = /  { gsub(/"/, "", $3); src = $3 }
		END { flush() }
	' "$1"
}

for lock in $(find "$dir" -name Cargo.lock -not -path '*/vendor/*' -not -path '*/target/*'); do
	ldir=$(dirname "$lock")
	for spec in "$@"; do
		crate=${spec%@*}; want=${spec#*@}; ws=$(series "$want")
		for have in $(registry_versions "$lock" "$crate"); do
			[ "$(series "$have")" = "$ws" ] || continue
			extra=""
			tries=0
			while [ $tries -lt 6 ]; do
				( cd "$ldir" && cargo update -p "$crate@$have" $extra ) >> "$log" 2>&1
				now=$(registry_versions "$lock" "$crate" | while read -r x; do [ "$(series "$x")" = "$ws" ] && echo "$x"; done)
				[ -z "$now" ] && break
				have=$(echo "$now" | head -1)
				# who keeps it? cargo says: required by package `nix v0.31.1`
				blocker=$( (cd "$ldir" && cargo update -p "$crate@$have" --precise "$want") 2>&1 | tee -a "$log" |
					sed -n 's/.*required by package `\([^ `]*\) v\([^`]*\)`.*/\1@\2/p' | head -1)
				[ -n "$blocker" ] || break
				case " $extra " in *" -p $blocker "*) break ;; esac
				echo "ilp32-cargo-lock: $crate@$have is held by $blocker, updating both" >> "$log"
				extra="$extra -p $blocker"
				tries=$((tries + 1))
			done
		done
		left=$(registry_versions "$lock" "$crate" | while read -r x; do [ "$(series "$x")" = "$ws" ] && echo "$x"; done)
		if [ -n "$left" ]; then
			echo "ilp32-cargo-lock: $lock still uses crates.io $crate $left (fixed: $want); see $log" >&2
			status=1
		fi
	done
done
exit $status
