#!/bin/sh
# One-line installer for tpkg on OpenWrt/ImmortalWrt.

set -u

REPO=${GITHUB_REPO:-Misaka1008611/OpenWrt-thirdparty-apk-updater}
BRANCH=${GITHUB_BRANCH:-main}
INSTALL_BIN=${INSTALL_BIN:-/usr/bin/tpkg}
INSTALL_CONF=${INSTALL_CONF:-/etc/config/tpkg}
RAW_BASE=${RAW_BASE:-https://raw.githubusercontent.com/$REPO/$BRANCH}

die() {
	printf '%s\n' "error: $*" >&2
	exit 1
}

have_cmd() {
	command -v "$1" >/dev/null 2>&1
}

fetch() {
	url=$1
	out=$2
	if have_cmd curl; then
		curl -fsSL -H "User-Agent: tpkg-installer" -o "$out" "$url"
	elif have_cmd wget; then
		wget -q --user-agent="tpkg-installer" -O "$out" "$url"
	else
		die "need curl or wget"
	fi
}

[ "$(id -u)" = "0" ] || die "please run as root"

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/tpkg-install.XXXXXX") || die "failed to create temp dir"
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

fetch "$RAW_BASE/tpkg" "$tmp_dir/tpkg" || die "failed to download tpkg"
fetch "$RAW_BASE/tpkg.conf" "$tmp_dir/tpkg.conf" || die "failed to download tpkg.conf"

grep -q 'Tiny third-party APK release checker' "$tmp_dir/tpkg" || die "downloaded tpkg does not look right"
grep -q '^TPKG_ITEMS=' "$tmp_dir/tpkg.conf" || die "downloaded tpkg.conf does not look right"

mkdir -p "${INSTALL_BIN%/*}" "${INSTALL_CONF%/*}" || die "failed to create install directories"
cp "$tmp_dir/tpkg" "$INSTALL_BIN" || die "failed to install $INSTALL_BIN"
chmod 0755 "$INSTALL_BIN" || die "failed to chmod $INSTALL_BIN"

if [ -f "$INSTALL_CONF" ]; then
	cp "$INSTALL_CONF" "$INSTALL_CONF.bak" || die "failed to backup existing config"
fi
cp "$tmp_dir/tpkg.conf" "$INSTALL_CONF" || die "failed to install $INSTALL_CONF"
chmod 0644 "$INSTALL_CONF" || die "failed to chmod $INSTALL_CONF"

printf '%s\n' "installed: $INSTALL_BIN"
printf '%s\n' "config:    $INSTALL_CONF"
printf '%s\n' "try:       tpkg check"
