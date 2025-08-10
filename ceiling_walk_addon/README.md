# Ceiling Walk Addon (Garry's Mod)

Walk on a chosen ceiling surface. Pick a surface with the Toolgun and your movement/camera will adapt so you can walk on the underside.

## Installation
- Copy `ceiling_walk_addon` into `garrysmod/addons/`.
- Restart the game/server.

## Usage
- Toolgun: Tools > Movement > Ceiling Walk
  - Right-click a ceiling surface to select it (uses the surface normal & hit position)
  - Left-click to enable/disable walking on that selected ceiling
  - Reload to toggle camera inversion while on the ceiling
  - Accel slider tunes how hard you are pulled to the ceiling
- Console (optional): `cw_demo` selects the surface you look at and enables.

## Notes
- Only applies when you are within ~128 units of the selected ceiling plane.
- Your base gravity is reduced while enabled to avoid conflicts; restored on disable.
- Fall damage is disabled while walking on the ceiling.