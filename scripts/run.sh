#!/usr/bin/env bash
# Launch the live.tips app on one or more targets.
#
#   ./scripts/run.sh iphone            # most recently active iPhone simulator
#   ./scripts/run.sh ipad iphone mac   # several at once
#   ./scripts/run.sh android           # running emulator, or boots the last-used AVD
#   ./scripts/run.sh web               # flutter run -d web-server, opens in the browser
#
# Device choice: an already-booted simulator wins; otherwise the one you
# used most recently (data-directory mtime) is booted. Everything runs the
# debug build. Requires: Xcode + simulators for iphone/ipad/mac, Android
# SDK (adb, emulator) for android.
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../app" && pwd)"
BUNDLE_ID="tips.live.liveTips"
ANDROID_PKG="tips.live.live_tips"
SIM_DEVICES_DIR="$HOME/Library/Developer/CoreSimulator/Devices"
WEB_PORT=8734

usage() {
  sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 1
}

log() { printf '\033[1;33m[run]\033[0m %s\n' "$*"; }

# Prints "UDID NAME" of the best simulator whose name matches $1 (regex).
# Booted beats shut down; ties broken by most recent use.
pick_simulator() {
  local name_regex="$1" json_file
  json_file=$(mktemp)
  xcrun simctl list devices available -j > "$json_file"
  local result=0
  python3 - "$name_regex" "$SIM_DEVICES_DIR" "$json_file" <<'PY' || result=$?
import json, os, re, sys
regex, devices_dir = re.compile(sys.argv[1], re.I), sys.argv[2]
data = json.load(open(sys.argv[3]))
candidates = []
for runtime, devices in data["devices"].items():
    if "iOS" not in runtime:
        continue
    for d in devices:
        if not regex.search(d["name"]):
            continue
        path = os.path.join(devices_dir, d["udid"])
        mtime = os.path.getmtime(path) if os.path.exists(path) else 0
        booted = d["state"] == "Booted"
        candidates.append((booted, mtime, d["udid"], d["name"]))
if not candidates:
    sys.exit(1)
best = sorted(candidates, reverse=True)[0]
print(best[2], best[3])
PY
  rm -f "$json_file"
  return $result
}

build_ios_done=""
ensure_ios_build() {
  if [[ -z "$build_ios_done" ]]; then
    log "Building iOS simulator app…"
    (cd "$APP_DIR" && flutter build ios --simulator --debug >/dev/null)
    build_ios_done=1
  fi
}

run_ios_simulator() {
  local kind="$1" regex="$2"
  local picked
  if ! picked=$(pick_simulator "$regex"); then
    log "No available $kind simulator found (xcrun simctl list devices)"; return 1
  fi
  local udid="${picked%% *}" name="${picked#* }"
  ensure_ios_build
  log "$kind → $name ($udid)"
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  open -a Simulator --args -CurrentDeviceUDID "$udid"
  xcrun simctl install "$udid" "$APP_DIR/build/ios/iphonesimulator/Runner.app"
  xcrun simctl launch "$udid" "$BUNDLE_ID" >/dev/null
  log "$kind: launched ✓"
}

run_mac() {
  log "Building macOS app…"
  (cd "$APP_DIR" && flutter build macos --debug >/dev/null)
  open "$APP_DIR/build/macos/Build/Products/Debug/live_tips.app"
  log "mac: launched ✓"
}

# Android SDK location: env vars first, then the default macOS install path.
android_sdk() {
  for candidate in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Library/Android/sdk"; do
    [[ -n "$candidate" && -x "$candidate/platform-tools/adb" ]] && { echo "$candidate"; return; }
  done
  return 1
}

# Prints the serial of a running emulator/device, if any.
android_running_device() {
  "$1/platform-tools/adb" devices | awk 'NR>1 && $2=="device" {print $1; exit}'
}

# Most recently used AVD by .avd directory mtime.
android_last_avd() {
  ls -1td "$HOME"/.android/avd/*.avd 2>/dev/null | head -1 \
    | xargs -I{} basename {} .avd
}

run_android() {
  local sdk
  if ! sdk=$(android_sdk); then
    log "Android SDK not found (set ANDROID_HOME or install via Android Studio)"; return 1
  fi
  local adb="$sdk/platform-tools/adb"
  local serial
  serial=$(android_running_device "$sdk" || true)
  if [[ -z "$serial" ]]; then
    local avd
    avd=$(android_last_avd)
    if [[ -z "$avd" ]]; then
      log "No Android device running and no AVDs found (create one in Android Studio)"; return 1
    fi
    log "Booting last-used AVD: $avd (this can take a minute)…"
    nohup "$sdk/emulator/emulator" -avd "$avd" >/dev/null 2>&1 &
    disown
    "$adb" wait-for-device
    until [[ "$("$adb" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do
      sleep 2
    done
    # boot_completed fires before the package manager is usable; wait for it
    until "$adb" shell pm path android >/dev/null 2>&1; do
      sleep 2
    done
    serial=$(android_running_device "$sdk")
  fi
  log "Building Android APK…"
  (cd "$APP_DIR" && flutter build apk --debug >/dev/null)
  log "android → $serial"
  local attempt
  for attempt in 1 2 3; do
    if "$adb" -s "$serial" install -r \
        "$APP_DIR/build/app/outputs/flutter-apk/app-debug.apk" >/dev/null 2>&1; then
      break
    fi
    [[ $attempt == 3 ]] && { log "android: install failed"; return 1; }
    sleep 5
  done
  "$adb" -s "$serial" shell monkey -p "$ANDROID_PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
  log "android: launched ✓"
}

run_web() {
  log "Launching web app…"
  local logfile
  logfile=$(mktemp)
  (cd "$APP_DIR" && nohup flutter run -d web-server --web-port="$WEB_PORT" >"$logfile" 2>&1 &)
  local waited=0
  until grep -q "is being served at" "$logfile" 2>/dev/null; do
    if (( waited >= 90 )); then
      log "web: timed out waiting for the dev server — see $logfile"; return 1
    fi
    sleep 1
    waited=$((waited + 1))
  done
  open "http://localhost:$WEB_PORT"
  log "web: launched ✓ ($logfile)"
}

[[ $# -ge 1 ]] || usage

for target in "$@"; do
  case "$(echo "$target" | tr '[:upper:]' '[:lower:]')" in
    iphone)      run_ios_simulator "iphone" '^iPhone' ;;
    ipad)        run_ios_simulator "ipad" '^iPad' ;;
    mac|macos)   run_mac ;;
    android)     run_android ;;
    web|chrome)  run_web ;;
    *)           log "Unknown target: $target"; usage ;;
  esac
done
