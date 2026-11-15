# Release verification — 0.6.1

- All 16 isolated headless source suites passed: 19,609 assertions, zero failures.
- Controls: 24 focused assertions verify placement, aim, power, spin, called balls/pockets, pause, deadzones, focus loss and AI-turn gating. The native device playthrough passed 24 checks through actual viewport input events, including the two-click mouse shot, keyboard-only menus, modal shooting protection and controller menu navigation. No physical gamepad was connected; controller hardware verification remains outstanding.
- Manual slots: 92 focused assertions, including ten independent slots, explicit overwrite confirmation, corruption rejection, no implicit progress saves and deterministic restoration of a moving shot.
- Rival outcomes: 638 assertions verify all 48 identities, 96 unique lines and the correct victory/defeat expression routing.
- Native mouse/keyboard playthrough: 21 manual-save/pause checks and 16 existing frontend/shooting checks passed. Save → Back → Resume, Journey → Escape → Resume and Help → Back → Resume were exercised using real viewport input events. Four new menu/result captures were visually checked.
- Clean Linux x86-64 export: all 53 compiled runtime checks passed, including eight embedded outcome atlases, 96 result lines and ten-slot UI controls.
- Native 1920×1080, Compatibility/Performance, Intel Mesa RPL-P: pool 59.62 fps, snooker 59.39 fps, GOAT AI 59.99 fps across 600/360/360 actual rendered frames. These are averages; occasional frames exceed 16.67 ms. Other hardware/drivers need verification.
- Automatic progress saving is removed. Legacy match.save files are ignored and left untouched. Settings and the Top Ten remain separate local records. No real player save files were used by these tests.
- Optional rival result recordings are not bundled: all dialogue is readable on screen, and exact filenames/lines are provided for later MP3 exports.
- Source and original project artwork/effects: Apache-2.0. Full font/engine notices included. Supplied music remains separately licensed for distribution within the game.
- Some Dummy-audio teardown runs emit Godot MP3 playback/resource reference warnings without failed assertions. Normal audio/mute checks pass.

Linux x86-64 with OpenGL 3.3-capable graphics is the supported package. The earlier strict-Snap software-rendered test confirmed functional behavior, but llvmpipe at 800×450 did not meet the 60 fps performance assertions. Native hardware performance above is the measured target; software rendering is not a 60 fps guarantee.
