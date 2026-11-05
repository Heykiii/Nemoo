# Noomi (prototype / alpha)

Swing. Release. Flip. Stick it. 2D physics gymnastics game for Android, built with Godot 4.3 (GDScript).

## Build the Android APK without a Mac toolchain (GitHub Actions)
1. Create a new GitHub repository (public is easiest).
2. Upload **all files in this folder** (keep the folder structure, including `.github/workflows/build-android.yml`).
3. Open the **Actions** tab -> "Build Android APK" -> it runs automatically on every push to `main` (or press *Run workflow*).
4. When it finishes (~5-8 min): open the repo's **Releases** page -> `Noomi debug build` -> download `noomi-debug.apk` on your Android phone and install it (allow "install unknown apps").
   The APK is also in the run's **Artifacts**.

## Controls
Touch buttons (or keyboard): PUMP `Space` | GRAB/RELEASE `E` | BACK FLIP `A` | FRONT FLIP `D` | TUCK `S` | EXTEND `W` | TWIST `Q` | Retry `R` | Pause `Esc`.
Hold PUMP to build swing; tap RELEASE on the forward swing; hold BACK/FRONT FLIP (+TUCK to spin faster); EXTEND slows the spin; land feet-first in the gold zone.

## Orientation / design notes
- Landscape, 1280x720 base, `expand` stretch (any aspect ratio), safe-area margins on HUD.
- Swing = analytic pendulum (stable, exact momentum transfer on release). Air = ballistic body with controlled spin; flips/twists are measured from accumulated rotation, points are banked once per flight.
- Tuning values are `@export` vars in `scripts/player/player.gd`, scoring constants in `scripts/gameplay/score_manager.gd`, levels in `scripts/core/level_data.gd`.
- Audio hooks exist; drop `grab.ogg, release.ogg, swing.ogg, trick.ogg, regrab.ogg, land.ogg, perfect.ogg, fall.ogg, level_complete.ogg, button.ogg` into `assets/audio/`.

## Status
Implemented: core swing/release/air/tricks/landing, scoring + combos, 10 campaign levels, Trick Rush, Chill mode, menus, results, versioned save, trick book, achievements, 3 character colors, tutorial hints in level 1, pause/restart/back handling.
Not done: real artwork/audio, ragdoll limbs, moving platforms/rings/trampolines, ads/IAP, sharing, release signing (see below), Play Store assets.
Tested: headless Godot 4.3 simulation (`tests/sim_test.tscn`, `tests/ui_test.tscn`). **Not yet tested on a real Android device or via the CI workflow - level difficulty needs playtesting and tuning.**

## Release build (later)
Create your own keystore, store it and passwords as GitHub Secrets (never commit them), and switch the export to `--export-release` with an AAB (needs gradle build enabled). Check current Google Play target-SDK rules first.
