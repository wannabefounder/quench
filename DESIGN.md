# Quench design system

Quench should explain one idea in a glance: **your water intake is racing the estimated water behind
your AI usage**. Personality invites attention; the numbers, labels, and open methodology earn trust.

## Experience hierarchy

1. A tiny draggable pixel-buddy panel stays above normal windows and shows only human goal progress,
   AI water, and the one-click log action. The native menu-bar icon remains the entry point because
   macOS may suppress or collapse custom status-item text.
2. The main window and menu-bar popover lead with the same live character reaction and one
   plain-language status sentence, so launching the app is never a blank or hidden experience.
3. Two labeled lanes—You and Your AI—show the race without relying on color alone.
4. “Log 250 mL” is the single dominant action. Streaks, Thirst Index, and source health are secondary.
5. Scope, region, privacy, and source accuracy remain visible without turning the popover into a dashboard.

## Four themes

- **Aqua Lab — Axel the Axolotl:** cyan/blue, scientist, cup and cooling-lab cues.
- **Forest Flow — Moss the Capybara:** green/mint, gardener, sprout and watering-can cues.
- **Cosmic Sip — Orbit the Otter:** purple/indigo, astronaut, bubbles and satellite cues.
- **Solar Splash — Kiko the Robot Koi:** orange/red, mechanical fish and water-gauge cues.

Every character supports the same semantic states: idle, AI drinking, user drinking, user ahead, AI
ahead, and tied. Themes change personality and palette, never calculations or meaning.

The application icon uses an original Aqua Lab illustration of Axel holding a glass of water. It is
kept as a high-resolution raster master because Dock and Finder rendering benefit from the soft 3D
surface treatment; the live Axel character remains native SwiftUI for motion and accessibility.

## Motion contract

- Ambient breathing, blinking, and contained bubbles make the buddy feel alive in the always-open
  main window and whenever the popover or theme gallery is visible.
- An increase in AI water triggers the AI-drinking state automatically; logging water triggers a
  short celebration. Resting expression follows the race state.
- Interaction never waits for animation. The menu bar uses the standard monochrome water-drop
  symbol beside calm, always-visible stats. It briefly rotates to “AI just drank” when new usage is
  found and to a configurable local sip reminder. Custom colored SwiftUI icons flatten into an
  unreadable black oval on macOS 26, while frame-rate timer labels trigger an AppKit layout loop.
- The always-on-top panel uses a non-activating native `NSPanel`, joins every Space, never observes
  other windows, and can be disabled in Settings. Its deliberately pixelated buddy communicates
  character without a frame-rate animation loop.
- With macOS Reduce Motion enabled, ongoing translation/rotation pauses; expression, glyph, and
  color changes preserve meaning.

This follows Apple's guidance that motion should convey status and feedback without overshadowing
the task, remain optional, and avoid being the sole information channel:
[Motion](https://developer.apple.com/design/human-interface-guidelines/motion),
[Reduce Motion](https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/accessibilityReduceMotion),
and [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility).

## Accessibility and platform fit

- Use text, symbols, and shape in addition to color; every buddy and race has a combined VoiceOver label.
- Respect Reduce Motion, system appearance, increased contrast, and semantic control behavior.
- Keep macOS targets at least 28×28 points and keep the primary action keyboard accessible.
- Use native materials and system controls for legibility across desktop tinting and light/dark mode.
- Quench is English-only per the product owner's 2026-07-18 decision; do not expose incomplete
  language choices or ship untranslated surfaces.

The character-led motivation draws on the approachable collection pattern documented by
[Waterllama](https://waterllama.com/), while Quench stays distinct through original characters and the
live human-vs-AI environmental race.
