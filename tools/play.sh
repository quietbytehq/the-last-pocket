#!/bin/sh
set -eu
game_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
case " $* " in
    *" --display-driver "*|*" --headless "*) exec "$game_dir/TheLastPocket.x86_64" "$@" ;;
esac
if [ "${XDG_SESSION_TYPE:-}" = wayland ] && [ -n "${WAYLAND_DISPLAY:-}" ]; then
    exec "$game_dir/TheLastPocket.x86_64" --display-driver wayland "$@"
fi
exec "$game_dir/TheLastPocket.x86_64" "$@"
