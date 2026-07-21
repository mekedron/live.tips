#!/usr/bin/env bash
# Boot a bare simulator for manual testing — no build, no app, nothing.
#
#   ./scripts/sim.sh                                    # iPhone (the default)
#   ./scripts/sim.sh iphone
#   ./scripts/sim.sh ipad
#   ./scripts/sim.sh ipad --url https://live.tips/app/  # …and open it in Safari
#   ./scripts/sim.sh iphone --restart                   # reboot it
#   ./scripts/sim.sh iphone --reset                     # wipe its data first
#
# Each kind gets ONE dedicated simulator — "LiveTips iPhone", "LiveTips iPad" —
# created on first use and reused forever after. So whatever you leave on it
# (Safari logins, cookies, home-screen PWAs, notification permissions) is still
# there next time, and the iPhone's state never mixes with the iPad's. Running
# the script again just brings the existing device to the front instead of
# piling up new simulators; both kinds can run side by side.
#
# Unlike scripts/run.sh this installs nothing: it is a clean device for poking
# at production from a real iOS Safari.
set -euo pipefail

DEVICE_TYPE_PREFIX="com.apple.CoreSimulator.SimDeviceType"

# First match wins, so newest hardware first — a machine with older Xcode
# simply falls further down the list.
IPHONE_TYPES=(iPhone-17-Pro iPhone-17 iPhone-16-Pro iPhone-16 iPhone-15-Pro iPhone-15)
IPAD_TYPES=(iPad-Pro-11-inch-M5-12GB iPad-Air-11-inch-M4 iPad-Pro-11-inch-M4-8GB
            iPad-Air-11-inch-M2 iPad-A16 iPad-10th-generation)

usage() {
  sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 1
}

# Status goes to stderr, so create_device's stdout stays a bare UDID.
log() { printf '\033[1;36m[sim]\033[0m %s\n' "$*" >&2; }

# Prints "UDID STATE AVAILABLE" for the device named exactly $1, or fails.
find_device() {
  local name="$1" json_file result=0
  json_file=$(mktemp)
  xcrun simctl list devices -j > "$json_file"
  python3 - "$name" "$json_file" <<'PY' || result=$?
import json, sys
name = sys.argv[1]
for devices in json.load(open(sys.argv[2]))["devices"].values():
    for d in devices:
        if d["name"] == name:
            print(d["udid"], d["state"], "yes" if d.get("isAvailable") else "no")
            sys.exit(0)
sys.exit(1)
PY
  rm -f "$json_file"
  return $result
}

# Prints the full identifier of the first device type from $@ that this Xcode has.
pick_device_type() {
  local installed
  installed=$(xcrun simctl list devicetypes -j \
    | python3 -c 'import json,sys; print("\n".join(t["identifier"] for t in json.load(sys.stdin)["devicetypes"]))')
  local candidate
  for candidate in "$@"; do
    if grep -qx "$DEVICE_TYPE_PREFIX.$candidate" <<<"$installed"; then
      echo "$DEVICE_TYPE_PREFIX.$candidate"
      return 0
    fi
  done
  return 1
}

# Prints the identifier of the newest installed iOS runtime.
newest_ios_runtime() {
  xcrun simctl list runtimes -j | python3 -c '
import json, sys
runtimes = [r for r in json.load(sys.stdin)["runtimes"]
            if r.get("isAvailable") and ".SimRuntime.iOS-" in r["identifier"]]
if not runtimes:
    sys.exit(1)
print(max(runtimes, key=lambda r: [int(p) for p in r["version"].split(".")])["identifier"])'
}

# Creates the device and prints its UDID.
create_device() {
  local name="$1"; shift
  local device_type runtime
  if ! device_type=$(pick_device_type "$@"); then
    log "None of these device types are installed: $*"; exit 1
  fi
  if ! runtime=$(newest_ios_runtime); then
    log "No iOS runtime installed — get one from Xcode → Settings → Components"; exit 1
  fi
  log "Creating \"$name\": ${device_type##*.} on ${runtime##*.SimRuntime.}"
  xcrun simctl create "$name" "$device_type" "$runtime"
}

kind="" url="" reset=0 restart=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    # New kinds (android…) get a branch here and in the case below.
    iphone|ipad) kind="$1" ;;
    --reset)     reset=1 ;;
    --restart)   restart=1 ;;
    --url)       shift; url="${1:-}" ;;
    --url=*)     url="${1#--url=}" ;;
    -h|--help)   usage ;;
    *)           log "Unknown argument: $1"; usage ;;
  esac
  shift
done

case "${kind:-iphone}" in
  iphone) device_name="LiveTips iPhone"; device_types=("${IPHONE_TYPES[@]}") ;;
  ipad)   device_name="LiveTips iPad";   device_types=("${IPAD_TYPES[@]}") ;;
esac

udid="" state="Shutdown"
if info=$(find_device "$device_name"); then
  read -r udid state available <<<"$info"
  if [[ "$available" != yes ]]; then
    # Its runtime was uninstalled — the device is a tombstone, start over.
    log "\"$device_name\" lost its runtime — recreating it"
    xcrun simctl delete "$udid"
    udid=""
  fi
fi
if [[ -z "$udid" ]]; then
  udid=$(create_device "$device_name" "${device_types[@]}")
  state="Shutdown"
fi

if (( reset )); then
  log "Erasing all data on \"$device_name\""
  xcrun simctl shutdown "$udid" 2>/dev/null || true
  xcrun simctl erase "$udid"
  state="Shutdown"
elif (( restart )) && [[ "$state" == "Booted" ]]; then
  log "Restarting \"$device_name\""
  xcrun simctl shutdown "$udid"
  state="Shutdown"
fi

if [[ "$state" == "Booted" ]]; then
  log "\"$device_name\" is already running — bringing it to the front"
else
  log "Booting \"$device_name\" ($udid)"
  xcrun simctl boot "$udid" 2>/dev/null || true
fi
xcrun simctl bootstatus "$udid" -b >/dev/null
open -a Simulator --args -CurrentDeviceUDID "$udid"

if [[ -n "$url" ]]; then
  log "Opening $url"
  xcrun simctl openurl "$udid" "$url"
fi
