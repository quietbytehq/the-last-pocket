# Release verification — 0.7.1

- The original 16 source suites plus the new champion/online suite passed: 19,628 assertions, zero failures. These cover rules, AI, manual saves, controls, all 48 rivals and the new ending/posting flow.
- New native title/ending/privacy playthrough: 9/9 checks passed. Title-only group art, final-win trophy scene, player name, Continue, champion share offer, F2/local-only and no unintended HTTP request were exercised with viewport key and mouse events. Rendered title, corrected trophy handover and privacy screens were visually inspected.
- Local Worker integration: 19 checks passed under real wrangler dev and disposable D1. Valid/best-per-name score, threshold/ceiling/increment/type validation, blocked/leetspeak name, unknown/prototype/array mode, concurrent six-per-hour limit, full salted IP hashes, admin access/deletion, generic server errors, real game post, and champion badge persistence alongside higher incomplete scores.
- Clean Linux x86-64 export: all 55 compiled runtime checks passed, including both new illustrations. At 1920×1080 Compatibility/Performance on Mesa Intel RPL-P, pool averaged 59.64 fps, snooker 60.00 fps and GOAT AI 59.39 fps across 600/360/360 real GPU frames. Individual frames may exceed 16.67 ms; other hardware/drivers require verification.
- User deployed the service at lastpocket.quietbytehq.uk before any public hostname request. Scripted live submission appeared and was removed through private admin. A separate actual game-code test submitted a simulated completed tournament: public score, champion badge and stored complete-run category were confirmed, then removed. Board confirmed empty afterwards. Keys were not printed; no other player entries were removed.
- Some Dummy-audio/headless exits emit ObjectDB/resource reference warnings without assertion failures. Normal playback/mute checks passed previously; original audio is unchanged.
- The trophy handover was revised twice after user review. The selected final art has the hero supporting the trophy base instead of holding the left handle.
- Source/original generated art: Apache-2.0. Fonts/engine/music retain NOTICE terms. The selected app icon is unchanged.

## Limits

Scores and World Champion claims are self-reported, not verified. Open source and a public submission endpoint allow made-up scores and name impersonation. Validation, rate limiting and moderation deter junk, not determined cheating. No extra play-time or completion-versus-score check was introduced. Manual saves stay local; the global service gets only chosen name, points, category and game version, after explicit confirmation.

The new local Snap is assembled with snap pack using the existing installed 0.6.1 runtime/support files and the freshly tested 0.7.0 game, updated metadata and network plug. This session cannot invoke Snapcraft's confined builder; the checked-in canonical recipe remains available via tools/build-snap.sh on a normal Snapcraft/LXD environment. Package/game hashes are compared before installation/publication. Installation and Store publication status are reported separately.

## AI game selection — 0.7.1

All nine competitive modes passed 103 focused assertions: mode startup, Amateur defaults, save/load of introductions and in-flight shots, actual AI plan execution, correct carom cue, rival advancement, legacy 8-ball restoration and exclusion of non-8-ball games from the existing global board. Native mouse playthrough passed 11 checks for the grid and launching 9-ball, snooker and three-cushion; the screen was visually inspected. The full source suite passed 19,731 assertions across 18 suites, with zero failures. These tests do not claim a full manual 48-rival playthrough in each game.

Practice remains solo. Championship saves retain the selected game; old saves default to 8-ball. Local record rows include the game type, while the existing public online board remains 8-ball only. No Worker redeployment is required.

The final 0.7.1 Linux export passed all 55 runtime checks. New 1080p averages: pool 59.69 fps, snooker 60.00 fps and GOAT AI 59.37 fps. The 0.7.1 local Snap is assembled from the installed runtime and this tested export, as described above; installation/publication require normal-terminal Snap commands because this session has NoNewPrivs set.

## Consistent arcade scale — 0.7.2

All 19 source suites passed (19,565 assertions, zero failures). New scale coverage includes all ten game types, matching projected ball diameter and cloth bounds, mesh/collision agreement, real collisions, and old/new save round trips. Old save geometry is carried through AI snapshots and subsequent saves; new frames use the common arcade dimensions. The snooker triangle and pink spot were repositioned to keep the enlarged balls clear.

The compiled Linux export passed 81 runtime checks at 1920×1080 on Mesa Intel RPL-P, Performance preset, full render scale, with real offscreen GPU draws. Average pool 59.89 fps, snooker 59.80 fps, carom 60.00 fps, GOAT AI 59.81 fps. Some individual frames exceed 16.67 ms; these averages are not a guarantee for other hardware. Four pocketless tier plates were generated with built-in image_gen; prompts and licence are recorded in docs/carom-art-prompts.json and NOTICE. Rendered snooker and carom screens were visually inspected. No Worker changes or deployment are required.

The Linux build is updated locally. Snap installation and Store upload require normal-terminal commands because this agent process cannot acquire the privileges required by Snap/sudo. The new Snap uses the installed runtime/support files and the tested 0.7.2 executable, with metadata updated from the canonical recipe.

## Windows x86-64 release — 21 November 2026

The Windows export was built from the same 0.7.2 game source and packaged with audio, controls, font/engine/media licence notices and a Windows player guide. ZIP integrity passed locally. Native GitHub Windows run 44930600642 passed all 19 source suites, verified the published ZIP SHA-256, extracted it and started the actual TheLastPocket.exe in headless mode for 120 iterations with exit code zero and no missing-resource/script errors. This is not a manual Windows GPU, audio-device, gamepad or performance test. The earlier 1080p FPS measurements are Linux measurements. Windows export support and verification workflows are now checked in.
