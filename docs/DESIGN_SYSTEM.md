# cscui Design System

This document is the visual and interaction contract for cscui, the Qt Quick
component workbench. It is intentionally inspired by Apple's Human Interface
Guidelines (HIG), while remaining an independent implementation and brand.
Use these tokens and rules when adding a component or page.

## Product principles

1. **Content first.** The component or inspected state is the primary object;
   chrome stays quiet and predictable.
2. **Clarity over decoration.** Use hierarchy, spacing, and semantic color
   before adding effects. Blur is reserved for transient surfaces such as a
   dialog or an inspector overlay.
3. **Respect the platform.** Keyboard navigation, native window behavior,
   reduced motion, and system text scaling must continue to work.
4. **One clear primary action.** Secondary and destructive actions are
   visually subordinate and spatially separated.

## Visual tokens

Tokens belong in the shared theme object. Components should not introduce
   arbitrary per-screen colors, radii, or shadow values.

### Color roles

The light and dark values below are semantic roles, not direct component
instructions. The exact values may be tuned with contrast tooling, but every
pair must preserve the stated contrast target.

| Role | Light | Dark | Usage |
| --- | --- | --- | --- |
| `background` | `#F5F5F7` | `#1C1C1E` | Window and page canvas |
| `surface` | `#FFFFFF` | `#2C2C2E` | Cards, panes, controls |
| `surfaceElevated` | `#FFFFFF` | `#323234` | Popovers and inspector |
| `textPrimary` | `#1D1D1F` | `#F5F5F7` | Headings and values |
| `textSecondary` | `#5C5C60` | `#AEAEB2` | Supporting labels |
| `separator` | `#D8D8DC` | `#3A3A3C` | Dividers and outlines |
| `accent` | `#0066CC` | `#66B2FF` | Focus, links, selected state (WCAG AA pair) |
| `selection` | `#D9ECFF` | `#193B61` | Selected surface behind accent text/icons |
| `onAccent` | `#FFFFFF` | `#1D1D1F` | Foreground chosen for accent-filled controls |
| `success` | `#34C759` | `#34C759` | Positive status (with text/icon) |
| `warning` | `#FF9F0A` | `#FF9F0A` | Caution status (with text/icon) |
| `danger` | `#FF3B30` | `#FF3B30` | Destructive state (with text/icon) |

Primary text must meet WCAG AA (4.5:1 for normal text, 3:1 for large text).
Secondary text must meet at least 3:1. The high-contrast theme uses
`#0052A3`/`#8CC8FF` for `accent` and `#C2E0FF`/`#234E73` for `selection`.
Never communicate a state through color alone; pair it with a label, icon, or
shape.

### Typography

Prefer the platform sans-serif family (`Segoe UI` on Windows, `SF Pro` when
available, and the Qt fallback chain elsewhere). Use the mono family for
metrics, IDs, and log output. Keep the type scale stable so content does not
move when a value changes.

| Token | Size | Weight | Typical use |
| --- | ---: | ---: | --- |
| `heading` | 22 px | 600 | Page and section heading |
| `title` | 17 px | 600 | Compact panel title |
| `body` | 13 px | 400 | Explanatory copy and control labels |
| `caption` | 11 px | 400 | Metadata and hints |
| `code` | 11 px | 400 | Debug values and paths |

Do not use condensed or negative letter spacing. Allow labels to wrap when
window width or user text scaling requires it.

### Geometry and motion

- Spacing follows a 4 px base grid: 4, 8, 12, 16, 24, 32, and 40 px.
- Use 8 px for small control radii, 12 px for cards, and 16 px for sheets.
- Interactive targets are at least 44 x 44 px, even if the visible glyph is
  smaller. Keep at least 8 px between adjacent targets.
- Use a single elevation scale. Avoid heavy shadows; a one-pixel separator is
  preferred for persistent panes.
- Micro-interactions run for 150-300 ms with an ease-out entrance and a faster
  exit. Animate opacity and transforms, not layout dimensions.
- Honor reduced motion by disabling non-essential transitions and continuous
  effects.

## Layout and navigation

The desktop workbench uses a stable three-region hierarchy: navigation,
content, and optional inspector. Keep the primary navigation visible and make
the current destination obvious by both color and text weight. The inspector
always reserves its own region; at narrow widths the navigation becomes compact
and secondary toolbar controls hide before content is allowed to overflow.

Keyboard focus order follows the visual order. Every icon-only control has a
descriptive accessible name and a visible focus ring. Never require hover or a
gesture for a critical action.

## Runtime performance contract

- Keep all QML items and Qt Quick scene-graph ownership on the GUI thread.
  Move only value-based filesystem, network, and data preparation work to
  bounded background workers.
- Prefer one low-priority worker for disk discovery. Cancel stale requests
  cooperatively and never wait for a worker from a page-destruction path.
- Apply large model results in bounded batches and virtualize or reuse list
  delegates. Debounce scroll-driven work and prefetch only near the viewport.
- Decode images asynchronously near their rendered dimensions. Avoid live
  `ShaderEffectSource` instances and full-window layers unless the effect is
  visible and actively changing.
- Animations should use opacity or transforms. Keep layout-property animation
  exceptional, short, interruptible, and disabled by reduced-motion mode.

## Debug mode contract

Run `cscui --debug-ui` to open the runtime inspector at startup. The toolbar
toggle controls the same state after launch. The inspector may expose:

- build mode, current page, viewport size, and measured frame rate;
- reduced-motion and high-contrast switches;
- layout-bound visualization and a bounded event log;
- a close action that returns focus to the invoking control.

Debug instrumentation must be read-only with respect to application data. It
must not alter production defaults, persist user data, or make network calls.
Frame rate is sampled from real scene-graph frame swaps; the inspector must not
keep the render loop awake solely to manufacture an FPS value. An idle scene is
reported as `Idle` rather than as a performance failure.
When the inspector is visible, event output is bounded (50 entries in the
current implementation) so long sessions do not grow memory without limit.

## Accessibility checklist

- Provide a semantic label and role for every interactive control.
- Keep focus indicators visible in both themes and at high contrast.
- Support keyboard activation and Escape dismissal for transient surfaces.
- Preserve readable layout at large text sizes; prefer wrapping to truncation.
- Offer a reduced-motion path and avoid flashing or rapid color changes.
- Pair status colors with text or icons and maintain contrast in both themes.
- Keep content clear of window chrome and leave enough padding for touch input
  on platforms that use touch.

## Migration notes

The product and QML module URI are now `cscui` (version `1.0`). Resource files
are served below `qrc:/cscui/`; replace `qrc:/new/prefix1/` references when
working in a component or template. New projects are created with
`tools/New-CscuiProject.ps1`, `tools/New-CscuiProject.sh`, or
`tools/New-CscuiProject.bat`. The previous `New-EvolveUIProject.*` names remain
as deprecation wrappers for existing automation and will be removed in a
future major release.
