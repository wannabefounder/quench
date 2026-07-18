# Quench design system

Quench should explain one idea in a glance: **your water intake is racing the estimated water behind
your AI usage**. Personality invites attention; the numbers, labels, and open methodology earn trust.

## Experience hierarchy

1. The menu-bar buddy is always visible and moves subtly without requiring a click.
2. The open popover leads with a live character reaction and one plain-language status sentence.
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

## Motion contract

- Ambient breathing, blinking, and contained bubbles make the buddy feel alive while visible.
- An increase in AI water triggers the AI-drinking state automatically; logging water triggers a
  short celebration. Resting expression follows the race state.
- Interaction never waits for animation. Menu-bar motion is lower-frequency than popover motion.
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
