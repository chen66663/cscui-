# cscui

cscui is an Apple-inspired Qt Quick component workbench for desktop and mobile
applications. It provides reusable QML controls, a live component gallery,
light and dark themes, and a runtime inspector for validating layout and
interaction states.

The visual language follows Apple's Human Interface Guidelines (HIG): clear
hierarchy, restrained surfaces, semantic color, predictable navigation,
keyboard support, and motion that communicates state. cscui is an independent
project and does not distribute Apple's proprietary assets.

## Highlights

- Qt 6.8 or newer with a C++17 application shell.
- Versioned QML module URI: `cscui`, version `1.0`.
- Shared theme tokens for light mode, dark mode, high contrast, and reduced
  motion.
- Component gallery for controls, data views, navigation, charts, media, and
  feedback.
- Optional runtime inspector with viewport, frame-rate, layout-bound, and event
  diagnostics.
- CMake warnings, compile database generation, and a CTest QML lint entry point.
- Scaffold templates for basic, mobile, and productivity applications.

See [the design system](docs/DESIGN_SYSTEM.md) for tokens, accessibility
rules, debug behavior, and migration notes.

## Requirements

- Qt 6.8+ with the Quick, Multimedia, and Network modules.
- CMake 3.24+.
- A C++17 compiler supported by the selected Qt kit.
- Font Awesome 6 desktop font files for the optional icon glyphs in
  `fonts/`.

## Build and run

~~~bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel
ctest --test-dir build --output-on-failure
~~~

For a multi-configuration generator:

~~~powershell
cmake --build build --config RelWithDebInfo --parallel
ctest --test-dir build -C RelWithDebInfo --output-on-failure
~~~

The generated `compile_commands.json` can be consumed by clangd, IDE
tooling, and static-analysis jobs. The application binary is named `cscui`
(or `cscui.exe` on Windows).

For single-configuration generators, an unspecified build type defaults to
`RelWithDebInfo`. This keeps runtime code optimized while retaining symbols for
profiling. Pass `-DCMAKE_BUILD_TYPE=Debug` explicitly when an unoptimized debug
build is required, or `-DCMAKE_BUILD_TYPE=Release` for deployment artifacts.

## Runtime performance model

- Qt Quick owns the GUI thread and uses the platform scene-graph render loop;
  QML objects must remain on the GUI thread.
- Recursive music discovery runs on one shared, low-priority worker thread.
  The bounded pool avoids competing disk walks when multiple media components
  exist, stale asynchronous results are discarded by generation number, and
  page destruction cancels cooperatively without waiting on the GUI thread.
- Large playlist results are applied in bounded per-frame batches. Metadata is
  prefetched only around the visible rows through a deduplicated, throttled
  queue, so scrolling does not compete with filesystem or multimedia work.
- Catalogue pages are incubated asynchronously so navigation and window input
  remain responsive while delegates and charts are constructed.
- `Carousel` decodes images near their rendered size, limits the maximum
  decode dimension, and loads only the current page and its neighbours by
  default. `cacheImages`, `lazyLoad`, `preloadRadius`, `decodeScale`, and
  `maxDecodeDimension` remain configurable for application-specific workloads.
- The UI inspector samples actual frame swaps without forcing the render loop
  to stay active while the window is idle.
- Media cover art is decoded asynchronously at bounded dimensions. Full-window
  blur and masking avoid redundant live sources and unnecessary cached layers.

## Runtime inspector

Start the workbench with the inspector open:

~~~bash
./build/cscui --debug-ui
~~~

The toolbar inspector toggle can open or close it after launch. The inspector
reports build mode, active page, viewport dimensions, frame rate, reduced-motion
and high-contrast state, layout bounds, and a bounded event log. It is intended
for local verification and does not persist application data.

For deterministic visual smoke tests, combine the screenshot and size options:

~~~bash
./build/cscui --page extended --theme dark --debug-ui --window-size 900x620 --screenshot build/cscui-dark.png
~~~

`--page` accepts `core`, `light`, or `extended` (numeric aliases `0`, `1`, and
`2` are also accepted). It is useful for deterministic page-level smoke tests
and does not change the in-app navigation behavior.

## Reusing the QML module

A consuming application can import the versioned module:

~~~qml
import cscui 1.0

ApplicationWindow {
    // Use controls exposed by the module.
}
~~~

For a source checkout copied into an application, local component imports remain
available:

~~~qml
import "components" as Components

Components.Button {
    text: "Continue"
}
~~~

Bundled non-QML assets use the stable resource prefix `qrc:/cscui/`:

~~~qml
FontLoader {
    source: "qrc:/cscui/fonts/fontawesome-free-6.7.2-desktop/otfs/Font Awesome 6 Free-Solid-900.otf"
}
~~~

## Scaffold a project

The canonical generators are safe to call from scripts and CI. They reject
invalid project names, restrict template selection to `scaffold/templates`,
and refuse to overwrite an existing directory.

PowerShell:

~~~powershell
.\tools\New-CscuiProject.ps1 -Name SampleApp -Destination . -Template basic -NonInteractive
~~~

Bash:

~~~bash
bash ./tools/New-CscuiProject.sh --name SampleApp --destination . --template basic --non-interactive
~~~

Windows command prompt:

~~~bat
tools\New-CscuiProject.bat -Name SampleApp -Destination . -Template basic -NonInteractive
~~~

Each generated project contains a CMake build, a `src.qrc` manifest, the
selected pages, and a copy of the reusable components and fonts. The previous
generator filenames remain as deprecation wrappers so existing automation can
transition without silently changing behavior.

## Component catalogue

The gallery includes controls and patterns such as:

- Buttons, icon buttons, inputs, switches, sliders, check boxes, radio buttons,
  menus, dropdowns, drawers, dialogs, toasts, and loaders.
- Cards, avatars, lists, tables, calendars, date pickers, carousels, clocks,
  progress indicators, and charts.
- Navigation bars, theme controls, media widgets, and the cscui debug panel.

Component filenames with the historical `E` prefix are retained as a source
compatibility surface. New components should use the `Csc` prefix and the
tokens documented in `docs/DESIGN_SYSTEM.md`.

## Engineering conventions

- Keep QML files in `components/` or `pages/`; CMake discovers only those
  two directories with narrow, configure-aware globs.
- Expose configurable behavior as typed properties with safe defaults.
- Use semantic theme values instead of hard-coded colors or shadows.
- Keep controls keyboard-operable and provide accessible names for icon-only
  actions.
- Respect reduced motion, large text, and high-contrast settings.
- Add a focused CTest or static-analysis check when changing shared behavior.
- Keep comments short and explain intent or a non-obvious constraint.

## Migration from the former product name

The executable, CMake project, QML URI, resource prefix, scaffold text, and
package identifiers are now branded `cscui`. Update consumers as follows:

| Before | cscui |
| --- | --- |
| `import EvolveUI` | `import cscui 1.0` |
| `engine.loadFromModule("EvolveUI", "Main")` | `engine.loadFromModule("cscui", "Main")` |
| `qrc:/new/prefix1/` | `qrc:/cscui/` |
| `New-EvolveUIProject.*` | `New-CscuiProject.*` |
| `com.sudoevolve.android` | `com.cscui.android` |

The compatibility generator wrappers emit a deprecation warning and delegate to
the canonical implementation. They are kept only for transition support.

## Links

- [Design system](docs/DESIGN_SYSTEM.md)
- [Qt Quick documentation](https://doc.qt.io/qt-6/qtquick-index.html)
- [Qt QML modules](https://doc.qt.io/qt-6/qtqml-modules-cppplugins.html)

Source, issue tracking, and release artifacts are maintained by the owning
organization. Keep those endpoints in deployment-specific documentation
rather than hard-coding an unverified public URL here.

## License

cscui is distributed under the MIT License. See [LICENSE](LICENSE).
