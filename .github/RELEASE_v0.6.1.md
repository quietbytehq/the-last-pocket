Mouse, keyboard and mapped gamepad controls now cover gameplay and menus.

- Mouse: click the cloth once to lock aim, then click again to shoot. Right-click unlocks. Placement and power/spin controls do not accidentally fire.
- Keyboard: arrows/WASD aim or place and set power, Shift for fine adjustment, Space/Enter places or shoots, IJKL/R for spin, Q/E or 1–6 calls pockets, C cycles called balls/colours.
- Gamepad: left stick aims/places, A places/shoots, triggers set power, D-pad fine-tunes aim/power, right stick/Y sets/resets spin, bumpers call pockets and X selects balls/colours. Start pauses/resumes; B pauses or backs out. D-pad/stick and A navigate menus.
- Visible keyboard/controller menu focus and device-specific hints. Disconnection or lost window focus clears held controls; controller disconnection pauses play. Inputs cannot fire on the AI turn or alter paused power.

Gamepad behavior was tested with simulated joypad events through the actual UI/input pipeline. No physical controller was connected, so controller hardware verification remains outstanding. Linux x86-64, offline; original code/art Apache-2.0, bundled media terms in NOTICE.

Snap gamepad setup: `sudo snap connect the-last-pocket:joystick`. The new package declares the controller interface; it does not request general raw-input access.
