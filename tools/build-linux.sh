#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p build/TheLastPocket/audio
touch build/.gdignore
"${GODOT:-godot}" --headless --editor --path . --import --quit
"${GODOT:-godot}" --headless --path . --export-release 'Linux Desktop' build/TheLastPocket/TheLastPocket.x86_64
cp tools/play.sh build/TheLastPocket/play.sh
cp tools/README-player.md build/TheLastPocket/README.md
cp RULES.md TOURNAMENT.md AUDIO_BRIEF.md ART_PROMPTS.md QA_REPORT.md RELEASE_VALIDATION.md NOTICE LICENSE build/TheLastPocket/
cp -R LICENSES build/TheLastPocket/
cp assets/ui/icon.png build/TheLastPocket/icon.png
printf '%s\n' '# Personal audio files' '' 'Drop the named MP3 files here and restart the game.' 'See ../AUDIO_BRIEF.md for prompts and filenames, and RIVAL_VOICE_LINES.csv for all 48 rival voice lines.' > build/TheLastPocket/audio/README.md
cp docs/RIVAL_VOICE_LINES.csv docs/RIVAL_RESULT_VOICE_LINES.csv build/TheLastPocket/audio/
chmod +x build/TheLastPocket/play.sh build/TheLastPocket/TheLastPocket.x86_64

mkdir -p build/TheLastPocket/docs
cp docs/table-v2-prompt.txt build/TheLastPocket/docs/
cp docs/current-build.png build/TheLastPocket/preview.png

cp docs/RIVAL_VOICE_LINES.csv docs/RIVAL_RESULT_VOICE_LINES.csv build/TheLastPocket/docs/
cp docs/campaign-art-prompts.json docs/result-art-prompts.json build/TheLastPocket/docs/

cp assets/audio/music.mp3 build/TheLastPocket/audio/music.mp3
