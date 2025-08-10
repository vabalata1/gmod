# Gravity Zone Addon (Garry's Mod)

Inverts gravity inside a selectable 3D zone so players can walk on the ceiling without breaking base animations.

## Installation

- Copy the `gravity_zone_addon` folder into your server or client `garrysmod/addons/` directory.
- Restart the game/server.

## Usage (Sandbox)

- Use the Toolgun: Tools > Gravity > Gravity Zone. Left-click to place/resize a zone, right-click on a surface to set gravity to pull toward it, reload to toggle view inversion. You can also spawn the entity `ent_gravity_zone` from the Entities tab (Gravity > Gravity Zone).
- Use the context menu (C) to rotate/position it. Its bounds define where inverted gravity applies.
- Default zone size ~512x512x256. You can resize via the toolgun `Size` tool or by editing the entity code to change bounds.

## Controls/Behavior

- Inside the zone, players are pulled toward the ceiling and can walk along it.
- Jump pushes the player away from the ceiling.
- View is rolled 180° so the horizon looks correct while inverted.
- Fall damage is disabled while inside the zone.

## Notes

- Source movement was not designed for arbitrary gravity directions. This addon uses custom movement in `SetupMove` to keep animations stable while faking ground adhesion.
- Complex map geometry or sharp edges may produce small snaps. Tune constants in `lua/autorun/gravity_zone.lua` if needed.

## Files

- `lua/entities/ent_gravity_zone/` — zone trigger entity
- `lua/autorun/gravity_zone.lua` — movement, camera, and hooks