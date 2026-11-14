#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
./tools/build-linux.sh
mkdir -p build/snap-payload/bin build/snap-payload/game build/snap-payload/usr/share/doc/the-last-pocket
cp -R build/TheLastPocket/. build/snap-payload/game/
cp tools/launch-snap.sh build/snap-payload/bin/launch-the-last-pocket
chmod +x build/snap-payload/bin/launch-the-last-pocket
cp LICENSE NOTICE build/snap-payload/usr/share/doc/the-last-pocket/
cp -R LICENSES build/snap-payload/usr/share/doc/the-last-pocket/
snapcraft pack --use-lxd --output build/
