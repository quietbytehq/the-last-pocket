#!/bin/sh
set -eu
export XDG_DATA_HOME="$SNAP_USER_COMMON/data"
export XDG_CONFIG_HOME="$SNAP_USER_COMMON/config"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
exec "$SNAP/game/play.sh" "$@"
