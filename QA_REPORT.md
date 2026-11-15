# Release verification — 0.6.0

All 15 isolated source suites passed (19,585 assertions). Manual-save UI input checks passed 21/21; existing frontend/shooting input checks passed 16/16. These cover explicit saving, overwrite confirmation, pause navigation, exact moving-shot restoration and all 48 rival outcomes. The clean exported game passed 53 runtime checks.

Native Linux x86-64, Godot 4.7.2 Compatibility/Performance, Mesa Intel RPL-P at 1920×1080: pool 59.57 fps, snooker 59.75 fps and GOAT AI 59.26 fps across 600/360/360 rendered frames. These are averages; occasional frames exceed 16.67 ms and other hardware/drivers need verification.

The supported release is Linux x86-64 with OpenGL 3.3-capable graphics. The previous strict Snap software-rendered run passed functional checks but missed the 60 fps assertions under llvmpipe. ARM, Windows and network multiplayer are not included. See RELEASE_VALIDATION.md for scope and limitations.
