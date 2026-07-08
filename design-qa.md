# Design QA

Reference: `design/concepts/selected-modern-table.png`
Implementation: `design/audit/final-home-fixed.png`

## Comparison

- Passed: compact opponent identity and card count are immediately visible.
- Passed: deck count and trump are grouped in the top HUD without stealing table space.
- Passed: the player hand is large, overlapping, readable, and keeps playable cards visually prominent.
- Passed: attack/defense state and the primary action use the target cyan/warm-red hierarchy.
- Fixed: table cards now center when one pair is present and remain horizontally scrollable for a full round.
- Intentional difference: the live app uses simpler card faces and Material icons to preserve clarity and performance across Android screen sizes.

## Latest polish pass

- Added a subtle fan rotation and raised playable cards.
- Disabled cards now have reduced opacity instead of looking tappable.
- Added haptic selection feedback and semantic card labels.
- Added animated table and turn-state transitions.
- Added an on-table deck and exposed trump indicator.
- Home screen now distinguishes Continue from New game.

## Future optional polish

- P3: custom face-card artwork and subtle deal animations can be added later.
- P3: haptic and sound settings are not yet exposed in the interface.

## Runtime verification

- Passed: the updated debug APK builds and installs successfully.
- Passed: the Flutter engine renders the first frame on the Android emulator.
- Passed: the final home screen is horizontally aligned and remains readable at 1080 x 2400.
- Passed: no application exceptions were recorded during the verified launch.

final result: passed
