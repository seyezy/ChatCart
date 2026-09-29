# ChatCart approved-logo palette alignment — v1.0.0

The supplied logo PNG is the **source of truth** and is preserved byte-for-byte. Its green is a gradient, not a single hex color. The values below are practical UI tokens selected to harmonize with the approved artwork, not claims of exact original vector stops.

| Token | Hex | Use |
|---|---|---|
| Primary / light | `#058139` | Buttons, active navigation, links |
| Primary / dark | `#10B64B` | Accessible brighter dark-mode accent |
| Gradient highlight | `#36CD38` | Decorative accents only |
| Gradient deep | `#058139` | Decorative gradient end |
| Brand deep | `#075C36` | Dark accents |
| Brand soft | `#E1F8E8` | Selected chips and pale surfaces |
| Brand ink | `#111C23` | Wordmark-inspired heading color |

Flutter, Figma, Laravel admin, sales landing page, HTML presentation and documentation CSS have been aligned. The Flutter and Figma logos use the actual approved PNG, not an inaccurate re-drawing. Figma image fill is editable/replacable, but the PNG is **not** editable vector paths.

The original reference artwork has a white background. On dark surfaces show it on a white tile; do not invert or recolor it. No routes, flavor IDs, environment files, Firebase configuration or backend behavior were intentionally changed.

Validation: PHP/JS syntax and JSON parsing can be checked locally; Flutter analysis/build and visual Figma execution require their respective toolchains.
