#!/usr/bin/env bash
# Launch the live.tips app on one target, in the foreground.
#
#   ./scripts/run.sh            # web (default): opens in the browser
#   ./scripts/run.sh web        # same as the default
#   ./scripts/run.sh iphone     # most recently active iPhone simulator
#   ./scripts/run.sh ipad       # most recently active iPad simulator
#   ./scripts/run.sh mac        # macOS desktop build
#   ./scripts/run.sh android    # running emulator, or the last-used AVD
#
# Every target runs flutter in the foreground, so you get the interactive
# console (r = hot reload, R = restart, q = quit) and Ctrl-C stops it. Run
# one target per invocation — open a new terminal tab for each.
#
# Device choice: an already-booted simulator wins; otherwise the one you
# used most recently (data-directory mtime) is booted. Everything runs the
# debug build. Requires: Xcode + simulators for iphone/ipad/mac, Android
# SDK (adb, emulator) for android.
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../app" && pwd)"
SIM_DEVICES_DIR="$HOME/Library/Developer/CoreSimulator/Devices"
WEB_PORT=8734

usage() {
  sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
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

run_ios_simulator() {
  local kind="$1" regex="$2"
  local picked
  if ! picked=$(pick_simulator "$regex"); then
    log "No available $kind simulator found (xcrun simctl list devices)"; return 1
  fi
  local udid="${picked%% *}" name="${picked#* }"
  log "$kind → $name ($udid)"
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  open -a Simulator --args -CurrentDeviceUDID "$udid"
  log "Launching on $name — Ctrl-C to stop (r: hot reload, R: restart, q: quit)"
  # flutter run builds, installs, launches, and attaches with hot reload.
  (cd "$APP_DIR" && flutter run -d "$udid")
}

run_mac() {
  log "Launching macOS app — Ctrl-C to stop (r: hot reload, R: restart, q: quit)"
  (cd "$APP_DIR" && flutter run -d macos)
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
  log "android → $serial — Ctrl-C to stop (r: hot reload, R: restart, q: quit)"
  # flutter run builds, installs, launches, and attaches with hot reload.
  (cd "$APP_DIR" && flutter run -d "$serial")
}

run_web() {
  # Free the port if a previous dev server is still holding it (e.g. a run that
  # was backgrounded or never cleanly stopped) so we don't fail with
  # "address already in use".
  local holders
  holders=$(lsof -ti tcp:"$WEB_PORT" 2>/dev/null || true)
  if [[ -n "$holders" ]]; then
    log "Port $WEB_PORT busy — stopping the old dev server ($(echo $holders | tr '\n' ' '))…"
    kill $holders 2>/dev/null || true
    local tries=0
    while lsof -ti tcp:"$WEB_PORT" >/dev/null 2>&1 && (( tries < 10 )); do
      sleep 1; tries=$((tries + 1))
    done
    holders=$(lsof -ti tcp:"$WEB_PORT" 2>/dev/null || true)
    [[ -n "$holders" ]] && kill -9 $holders 2>/dev/null || true
  fi

  log "Launching web app on http://localhost:$WEB_PORT — press Ctrl-C to stop"
  # Open the browser once the server accepts connections. This runs in the
  # background because flutter itself owns the foreground below.
  (
    n=0
    until curl -s -o /dev/null "http://localhost:$WEB_PORT"; do
      (( n++ >= 90 )) && exit 0
      sleep 1
    done
    open "http://localhost:$WEB_PORT"
  ) &
  local opener=$!
  trap 'kill "$opener" 2>/dev/null || true' RETURN

  # Foreground: the script stays attached, Ctrl-C stops the server, and you get
  # flutter's interactive console (press r to hot reload, R to restart, q to quit).
  (cd "$APP_DIR" && flutter run -d web-server --web-port="$WEB_PORT")
}

# No target → web. Exactly one target per run: each launches flutter in the
# foreground, so run several by opening a new terminal tab per target.
if [[ $# -eq 0 ]]; then
  set -- web
elif [[ $# -gt 1 ]]; then
  log "One target at a time — open a new terminal tab for each (got: $*)"
  usage
fi

case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
  iphone)      run_ios_simulator "iphone" '^iPhone' ;;
  ipad)        run_ios_simulator "ipad" '^iPad' ;;
  mac|macos)   run_mac ;;
  android)     run_android ;;
  web|chrome)  run_web ;;
  *)           log "Unknown target: $1"; usage ;;
esac
