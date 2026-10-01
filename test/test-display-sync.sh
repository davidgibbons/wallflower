#!/bin/bash
# Drives the presence state machine without X, HA, or a panel.
set -u
HA_DISPLAY_SYNC_LIB=1 . "$(dirname "$0")/../rootfs/usr/local/bin/ha-display-sync"

fail=0
is_on="-" streak=0
step() { # <state> <expected-action>
    read -r action is_on streak <<<"$(decide "$1" "$is_on" "$streak" 3)"
    if [ "$action" != "$2" ]; then
        echo "FAIL: state=$1 expected=$2 got=$action (is_on=$is_on streak=$streak)"
        fail=1
    fi
}
reset() { is_on="-" streak=0; }

# Booting while away blanks the panel on the third confirmed off.
reset; step off wait; step off wait; step off off; step off wait

# Arriving turns it on once, then just refreshes the screensaver inhibit.
reset; step on on; step on keepalive; step on keepalive

# A single off read between on reads must not blank anything.
reset; step on on; step off wait; step on keepalive; step off wait; step off wait

# Leaving after being present: three confirms, then off.
reset; step on on; step off wait; step off wait; step off off

# Unavailable counts toward the off streak; garbage states change nothing.
reset; step unavailable wait; step "" unknown; step standby wait; step off off

# Presence needs URL, entity and token; any one missing leaves the panel lit.
check_presence() { # <expect 0|1> <url> <entity> <token>
    HA_URL=$2 HA_ENTITY=$3 HA_TOKEN=$4 presence_configured; got=$?
    [ "$got" = "$1" ] || { echo "FAIL: presence_configured url='$2' entity='$3' token='$4' -> $got"; fail=1; }
}
check_presence 0 http://ha.test binary_sensor.desk t
check_presence 1 "" binary_sensor.desk t
check_presence 1 http://ha.test "" t
check_presence 1 http://ha.test binary_sensor.desk ""

[ $fail -eq 0 ] && echo "PASS: all display-sync transitions ok"
exit $fail
