# Release verification — 0.7.0

Source checks: 19,628 assertions across 17 suites, zero failures. New native title/ending/privacy checks: 9/9. Local Worker/D1 integration checks: 19/19, including actual game submission and champion badge aggregation. Live score, champion badge and admin cleanup passed after user deployment; board empty after testing. See RELEASE_VALIDATION.md for test scope and limitations.

Clean Linux export: 55 runtime checks passed. At native 1920×1080 Compatibility/Performance on Mesa Intel RPL-P: pool 59.64 fps, snooker 60.00 fps, GOAT AI 59.39 fps. These are averages, not guarantees for every frame or device. The earlier llvmpipe strict-Snap test did not reach 60 fps. Linux x86-64/OpenGL 3.3 is supported; Windows, ARM and network multiplayer are not included.

Scores and champion claims are self-reported; fake submissions remain possible. Personal score sharing is explicit and optional, remembers local-only and never uploads local history or save slots. Offline posts are silently dropped.
