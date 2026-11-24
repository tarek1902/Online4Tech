#!/bin/sh
# Online4Tech Panel 7.5 Gold - verified package installer
set -eu

BASE_URL="https://raw.githubusercontent.com/online4tech/Online4Tech-Panel1/main"
TMP_PKG="/tmp/enigma2-plugin-extensions-online4tech_7.5_all.pkg.$$"

cleanup() {
    rm -f "$TMP_PKG"
}
trap cleanup 0 HUP INT TERM

echo "===================================================="
echo "   Installing Online4Tech Panel 7.5 Gold Edition   "
echo "===================================================="

if command -v dpkg >/dev/null 2>&1 && [ -f /var/lib/dpkg/status ]; then
    PKG_NAME="enigma2-plugin-extensions-online4tech_7.5_all.deb"
    PKG_TYPE="DreamOS / dpkg"
elif command -v opkg >/dev/null 2>&1; then
    PKG_NAME="enigma2-plugin-extensions-online4tech_7.5_all.ipk"
    PKG_TYPE="Enigma2 / opkg"
else
    echo "[ERROR] No supported package manager found (dpkg/opkg)."
    exit 1
fi

PKG_URL="$BASE_URL/$PKG_NAME"
echo "-> Detected package manager: $PKG_TYPE"
echo "-> Downloading official Online4Tech package..."

if command -v wget >/dev/null 2>&1; then
    wget -qO "$TMP_PKG" "$PKG_URL"
elif command -v curl >/dev/null 2>&1; then
    curl -fLsS "$PKG_URL" -o "$TMP_PKG"
else
    echo "[ERROR] Neither wget nor curl is available."
    exit 1
fi

if [ ! -s "$TMP_PKG" ]; then
    echo "[ERROR] Package download failed or returned an empty file."
    exit 1
fi

ARCHIVE_MAGIC="$(dd if="$TMP_PKG" bs=8 count=1 2>/dev/null || true)"
if [ "$ARCHIVE_MAGIC" != "!<arch>" ]; then
    echo "[ERROR] Downloaded file is not a valid IPK/DEB archive."
    exit 1
fi

echo "-> Installing without force-overwrite..."
if [ "$PKG_TYPE" = "DreamOS / dpkg" ]; then
    dpkg -i "$TMP_PKG"
else
    opkg install --force-reinstall "$TMP_PKG"
fi

sync
echo "===================================================="
echo "   Online4Tech Panel package installed successfully "
echo "===================================================="
echo "Restarting Enigma2 GUI..."

if command -v systemctl >/dev/null 2>&1; then
    if systemctl restart enigma2.service 2>/dev/null || systemctl restart enigma2 2>/dev/null; then
        exit 0
    fi
fi

if command -v init >/dev/null 2>&1; then
    init 4
    sleep 3
    init 3
else
    echo "[INFO] Please restart the Enigma2 GUI manually."
fi

exit 0
