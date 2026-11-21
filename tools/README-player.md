# The Last Pocket — Linux development build

Run `play.sh` in this folder. From a terminal opened here:

```sh
./play.sh
```

Godot is not required. The launcher selects Wayland automatically on a Wayland desktop. This build is for 64-bit Linux with working OpenGL 3.3-compatible graphics.

The Performance graphics preset is selected on first launch; High is available from Pause. The frame limiter targets 60 fps. See QA_REPORT.md for measured results and remaining performance limits.

Press any key at the illustrated title screen. Choose Local Versus for two humans, or Versus AI for the championship. There is no difficulty selection: new AI runs start in Amateur. The game runs offline; there is no networking.

The championship has twelve rivals in each rank: Amateur, Professional, Master and GOAT. Three retry diamonds buy rematches after losses. Tables and cues upgrade between ranks, and the local Top Ten saves your personal best. See TOURNAMENT.md.

- Move mouse: aim.
- Aim, click to lock direction, then press Space / Enter or click Shoot. Right-click unlocks.
- Enter: shoot at the selected power.
- Mouse wheel: adjust power; left meter can also be dragged without firing.
- Click during ball in hand: place cue ball in a legal clear position.
- White ball control at lower right: cue spin; right mouse resets it.
- Keys 1–6 or a numbered pocket marker: call a pocket. After clearing your seven balls, choose the 8-ball pocket before shooting. Use the selector for called balls / snooker colours.
- H: help. Escape: pause. F11: fullscreen. F3: FPS.
- M: effects. N: music.

Tournament progress is never saved automatically. Choose Save tournament from Pause, an introduction or a result card, then choose one of ten slots. Each slot shows the player name and local date/time. Overwriting asks you to click again. Load tournament opens a chosen save; a live frame starts paused until Resume play. A shot in motion can be saved and restored exactly. Old automatic saves are ignored.

Local play has ten modes. Versus AI is the sequential 8-ball championship. These use the club rules and simplifications described in RULES.md, rather than a complete tournament-referee implementation.

Original stereo impact placeholders are included. Put your personal MP3 effects and music in the `audio` subfolder, using the filenames in AUDIO_BRIEF.md, and restart. The supplied two-minute stereo hotel-lobby track is included. Gameplay is designed for calm hotel-lobby lounge music. Music and SFX have separate icons and Pause switches, plus N / M shortcuts.

The Last Pocket 0.7.0 by QuietByte. Pocketed-table graphics use a detailed rendered table plate with live 3D balls, cue, shadows and interactive physics. The overhead view is fixed; carom retains the earlier 3D table.

QuietByte · hello@quietbytehq.uk

Source code: https://github.com/quietbytehq/the-last-pocket
Apache-2.0 source code; bundled media terms are in NOTICE.

## Mouse, keyboard and gamepad

Mouse: move to aim, click the cloth once to lock direction, then click again to fire. Right-click unlocks; the wheel or left meter sets power. Clicking during ball in hand only places the cue ball. The on-screen Shoot button also fires.

Keyboard: Left/Right or A/D rotates aim; Up/Down or W/S sets power. Hold Shift for fine aim or slower placement. During ball in hand, arrows/WASD move the cue ball and Space/Enter places it. Press Space/Enter again to shoot. I/J/K/L adjusts spin; R resets it. Q/E cycles pockets, or use 1–6; C cycles called balls or snooker colours. Tab/arrows navigate menus and Enter chooses.

Gamepad (standard mapped layout): left stick aims or moves the cue ball; A places or shoots. Triggers or D-pad Up/Down adjust power; D-pad Left/Right fine-tunes aim. Right stick sets spin; Y resets it. LB/RB cycles pockets; X cycles called balls/colours. Start pauses/resumes. B pauses at the table or goes back in menus. D-pad/left stick navigates menus; A chooses. Controller disconnection pauses play. Xbox-labelled controls correspond to the standard mapped positions on other controllers.

Gameplay inputs work only on the human turn and do not change the paused table. Moving the mouse or using keyboard/gamepad controls switches the active input hints. No controller is required to play.

For the Snap build, enable controller access once:

```sh
sudo snap connect the-last-pocket:joystick
```

The package declares only the game-controller input interface; it does not request general raw-input access. See [Snap controller access](https://snapcraft.io/docs/reference/interfaces/joystick-interface/).

The title now shows the hero and rival cast together. Beat all 48 rivals to see the personalized World Champion trophy presentation. After ending a qualifying championship, choose a public name and whether to post to the global top 100. F2 / gamepad X toggles remembered local-only; Escape/B keeps this score local. Only name, points, run category and version are sent. Scores and champion badges are self-reported, not verified. Offline posts are dropped silently. No local score history or save slots are uploaded.
