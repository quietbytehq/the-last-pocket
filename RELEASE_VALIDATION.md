# Public release verification — 0.5.4

- Clean public source: 13 isolated headless suites, 18,850 assertions, zero failed assertions.
- Clean Linux x86-64 export: all 41 compiled runtime checks passed.
- Native1920×1080, Compatibility/Performance, Intel Mesa RPL-P: pool59.66fps, snooker60.00fps, GOAT AI59.98fps across600/360/360 actual rendered frames. Hardware, driver and background load affect results; occasional frames exceed16.67ms.
- The reported final8-ball stall was reproduced: it required a called pocket, with its instructions hidden.25 regression assertions and6 native input checks verify numbered selection and actual shooting after a call.
- Public-tree text scan: no personal identity, absolute development paths, secrets or local account configuration found. Local/editor caches, builds, private checkpoints, user saves, logs and alternate branding drafts are excluded. Git author and committer use the QuietByte publishing identity.
- Code and original project graphics/effects: Apache-2.0. Full font/engine notices included. Public redistribution of the supplied music was confirmed by the project owner; it remains separately licensed for distribution within the game.
- Some Dummy-audio teardown runs emit Godot MP3 playback/resource reference warnings. They do not fail the assertions; normal playback, mute and save/restore checks pass.


Version0.5.4 changes packaging metadata only: the Snap licence label uses the compatible capitalized Proprietary spelling. Source code remains Apache-2.0; bundled music has separate terms. Gameplay code is identical to the tested0.5.3 build.
