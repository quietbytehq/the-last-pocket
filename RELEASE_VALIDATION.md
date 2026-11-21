# Release verification — 0.7.0

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
