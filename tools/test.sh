#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM
export XDG_CONFIG_HOME="$test_dir/config"
"${GODOT:-godot}" --headless --editor --path . --import --quit
for test_file in tests/test_*.gd; do
  test_name=$(basename "$test_file" .gd)
  XDG_DATA_HOME="$test_dir/$test_name" timeout 180s "${GODOT:-godot}" --headless --path . --script "$test_file"
done
