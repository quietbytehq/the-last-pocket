# Release verification — 0.5.3

Linux x86-64, Godot 4.7.2 Compatibility. Native Wayland/OpenGL tested on Mesa Intel RPL-P at1920×1080. The development build averaged59.88 fps in pool,59.99 fps in snooker and59.81 fps in GOAT AI across600/360/360 real rendered frames. These are averages; occasional frames exceed16.67ms and other drivers/hardware need verification.

The final8-ball pocket-call case passed25 focused source checks,57 integration checks and6 actual mouse-input checks. The exported game passed41 runtime checks. The eight must be played into a called pocket: numbered pocket markers, a persistent prompt and the shot button now explain this requirement.

Earlier verification covered deterministic rules, contact accuracy, AI difficulty, campaign progression, saves, audio, pocket boundary safety, rendered drop masks, white cue preview, side HUD collections and animated aiming. The full source suites and clean public export are rerun during release preparation; see RELEASE_VALIDATION.md for final outcomes.

The supported release is Linux x86-64 with OpenGL3.3-capable graphics. ARM, Windows, network multiplayer and tournament-referee certification are not offered. This is an offline game with local two-player and AI play.
