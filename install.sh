#!/bin/bash
#
# Build, package, sign, and install Mac Power Tools to /Applications.
#
# Run this whenever you change source. It handles the full "from a fresh clone to a
# working menu-bar icon" path.

set -euo pipefail

APP_NAME="MacPowerTools"
APP_BUNDLE="${APP_NAME}.app"
INSTALL_PATH="/Applications/${APP_BUNDLE}"
BUNDLE_ID="com.macpowertools.macpowertools"

cd "$(dirname "$0")"

# 1. Stop any running instances. Multiple copies = confusing menu bar state.
echo "🛑 Stopping any running ${APP_NAME}..."
pkill -x "${APP_NAME}" 2>/dev/null || true
pkill -f "${APP_BUNDLE}/Contents/MacOS" 2>/dev/null || true
sleep 1

# 2. Build the binary. build.sh handles compilation; we don't duplicate that here.
echo "🔨 Building binary..."
./build.sh > /tmp/macpowertools-build.log 2>&1 || {
    echo "❌ Build failed. Last 20 lines of log:"
    tail -20 /tmp/macpowertools-build.log
    exit 1
}

# 3. Package into a fresh .app bundle. create_apps.sh writes Info.plist and signs the
#    bundle with a stable identifier (see comment in create_apps.sh).
echo "📦 Packaging .app bundle..."
./create_apps.sh > /tmp/macpowertools-package.log 2>&1 || {
    echo "❌ Packaging failed. Last 20 lines of log:"
    tail -20 /tmp/macpowertools-package.log
    exit 1
}

# 4. Replace the installed copy. Removing first avoids merge-write issues from cp.
echo "📥 Installing to ${INSTALL_PATH}..."
if [ -d "${INSTALL_PATH}" ]; then
    rm -rf "${INSTALL_PATH}"
fi
cp -R "${APP_BUNDLE}" "${INSTALL_PATH}"

# 5. Refresh Launch Services so macOS notices the new bundle (otherwise some prompts
#    keep targeting an old codesign hash that's no longer on disk).
echo "🔄 Refreshing Launch Services..."
LSREG=/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister
if [ -x "${LSREG}" ]; then
    "${LSREG}" -f "${INSTALL_PATH}" >/dev/null 2>&1 || true
fi

# 6. Launch.
echo "🚀 Launching ${APP_NAME}..."
open "${INSTALL_PATH}"

# 7. First-run permission guidance. We can't grant TCC permissions for the user, but
#    we can tell them what to expect.
cat <<EOF

✅ Installed at: ${INSTALL_PATH}
   Bundle ID:   ${BUNDLE_ID}

📋 Permissions to grant on first use:

   Screen Recording (for Cmd+Shift+Y text extraction)
     - On first hotkey press, macOS will prompt
     - If no prompt appears, grant manually:
       System Settings → Privacy & Security → Screen Recording
       → enable "MacPowerTools"

   Accessibility (for global hotkeys + auto-paste)
     - System Settings → Privacy & Security → Accessibility
       → enable "MacPowerTools"

   After granting either permission, quit (⌬ menu → Quit) and relaunch.

💡 Look for the ⌬ icon in your menu bar.
EOF
