#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p build/TheLastPocket-Windows/audio build/TheLastPocket-Windows/docs
touch build/.gdignore
"${GODOT:-godot}" --headless --editor --path . --import --quit
"${GODOT:-godot}" --headless --path . --export-release 'Windows Desktop' build/TheLastPocket-Windows/TheLastPocket.exe
cp LICENSE NOTICE RULES.md TOURNAMENT.md AUDIO_BRIEF.md ART_PROMPTS.md QA_REPORT.md RELEASE_VALIDATION.md build/TheLastPocket-Windows/
cp -R LICENSES build/TheLastPocket-Windows/
cp tools/README-windows.md build/TheLastPocket-Windows/README.md
cp assets/ui/icon.png build/TheLastPocket-Windows/icon.png
cp assets/audio/music.mp3 build/TheLastPocket-Windows/audio/music.mp3
cp docs/RIVAL_VOICE_LINES.csv docs/RIVAL_RESULT_VOICE_LINES.csv build/TheLastPocket-Windows/audio/
cp docs/campaign-art-prompts.json docs/result-art-prompts.json docs/championship-art-prompts.json docs/carom-art-prompts.json build/TheLastPocket-Windows/docs/
