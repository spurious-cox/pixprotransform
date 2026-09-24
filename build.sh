#!/bin/zsh
# Build, sign and install PixProTransform.app — v1.4.0
#
# osacompile writes a bare applet, so the bundle identity has to be put back
# every time: CFBundleIdentifier, version, copyright and the Apple Events
# usage string are all lost on recompile.
#
# v1.3.0 moved from the Apple Development certificate to Developer ID, which
# is what distribution outside the App Store requires and what notarization
# accepts. Three things travel together and none is optional:
#
#   * the identity is selected by SHA-1 HASH, not by name — expired
#     certificates sharing the same name are still in the keychain and
#     signing by name can pick a dead one
#   * --timestamp, so the signature outlives the certificate
#   * --options runtime (the hardened runtime), which notarization requires,
#     together with the apple-events entitlement — the hardened runtime
#     otherwise blocks this applet from driving Pixelmator at all
#
# CHANGING THE SIGNING IDENTITY RESETS THE TCC GRANTS. Accessibility and
# Automation are keyed to the code signature, so the first run after this
# build will ask for permission again. That is expected, once.
#
# Notarize afterwards with (it signs only in its own mode, so use notarize):
#   ~/My_Applications/_signing/pixpro_release.sh notarize /Applications/PixProTransform.app
set -e
cd "${0:A:h}"

SIGN_ID="4208ABA3EC12F24C1F09C7BB624EFF68B44259DB"   # Developer ID Application
ENTS="pixprotransform.entitlements"
APP="PixProTransform.app"
# Read from the script itself, so the bundle can never claim a version the
# code does not. Hard-coding it here shipped an app whose dialogs and whose
# Get Info disagreed.
VERSION=$(/usr/bin/sed -n 's/^property scriptVersion : "\(.*\)"/\1/p' PixProTransform.applescript)
[[ -n "$VERSION" ]] || { echo "error: no scriptVersion in PixProTransform.applescript" >&2; exit 1; }

if ! security find-identity -p codesigning | grep -q "$SIGN_ID"; then
    echo "error: signing identity $SIGN_ID not in keychain (renewed cert?)" >&2
    exit 1
fi
[[ -f "$ENTS" ]] || { echo "error: entitlements missing: $ENTS" >&2; exit 1; }

echo "==> compiling"
rm -rf "$APP"
osacompile -o "$APP" PixProTransform.applescript

echo "==> installing the icon"
# osacompile ships a generic applet.icns; replace it and name it explicitly so
# the source of the icon is obvious in the bundle.
cp icon/PixProTransform.icns "$APP/Contents/Resources/PixProTransform.icns"
rm -f "$APP/Contents/Resources/applet.icns"
# Assets.car only carries the stock applet icon; with CFBundleIconName removed
# below it is dead weight, and leaving it invites the old icon back.
rm -f "$APP/Contents/Resources/Assets.car"

echo "==> restoring bundle identity (osacompile drops it)"
/usr/bin/python3 - "$APP" "$VERSION" <<'PY'
import plistlib, sys
p = sys.argv[1] + "/Contents/Info.plist"
version = sys.argv[2]
d = plistlib.load(open(p, "rb"))
d.update({
    "CFBundleName": "PixProTransform",
    "CFBundleDisplayName": "PixProTransform",
    "CFBundleIdentifier": "com.timmccoy.pixprotransform",
    "CFBundleShortVersionString": version,
    "CFBundleVersion": version,
    "NSHumanReadableCopyright": "Copyright © 2026 Tim McCoy. All rights reserved.",
    "CFBundleGetInfoString":
        "PixProTransform — opens Pixelmator Pro's Perspective Transform in one step.",
    "NSAppleEventsUsageDescription":
        "PixProTransform opens the Perspective Transform effect in Pixelmator Pro for you.",
    "CFBundleIconFile": "PixProTransform",
})
# CFBundleIconName points into Assets.car, where osacompile puts the generic
# applet icon — and the asset catalog WINS over CFBundleIconFile. Leaving this
# key in place means the custom icns is shipped but never used.
d.pop("CFBundleIconName", None)
plistlib.dump(d, open(p, "wb"))
PY

# The applet stub is copied from THIS machine by osacompile, so it carries
# this system's minimum macOS. Stamped back before signing — codesign seals
# whatever it finds. See ~/bin/pixpro_lower_min.
~/bin/pixpro_lower_min "$APP"

# The macOS 26+ icon. The stock Assets.car and its CFBundleIconName are
# removed above; this installs an Assets.car holding the app's own Icon
# Composer icon, which macOS 26+ uses instead of the .icns (still what
# macOS 13-25 show). See ~/bin/glass_icon.
~/bin/glass_icon "$APP" icon/AppIcon.icon

echo "==> signing with Developer ID ($SIGN_ID)"
codesign --force --deep --timestamp --options runtime \
    --entitlements "$ENTS" --sign "$SIGN_ID" "$APP"
codesign --verify --deep --strict "$APP"

echo "==> installing to /Applications"
rm -rf "/Applications/$APP"
cp -R "$APP" /Applications/
xattr -dr com.apple.quarantine "/Applications/$APP" 2>/dev/null || true

echo "==> installed:"
codesign -dv "/Applications/$APP" 2>&1 | grep -E "Identifier=|Authority="
plutil -extract CFBundleShortVersionString raw "/Applications/$APP/Contents/Info.plist"
echo
echo "Needs Accessibility access to click Pixelmator's menus:"
echo "  System Settings > Privacy & Security > Accessibility"
echo
echo "If Finder still shows the old icon, it is caching it:  killall Finder"
