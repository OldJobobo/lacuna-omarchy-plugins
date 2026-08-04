# Desktop ambience

Status: user guide for the latest beta

Lacuna can compose optional visual effects around the desktop while remaining
inside Omarchy's one shell process. Ambience is decoration: disabling it does
not remove the bar, sidebar, or system controls.

## Enable ambience

Open **Lacuna Settings → Animations** and enable the effects you want. Available
families include tracking lines, film grain, dust motes, aurora, rainfall,
cinematic light, god rays, CRT, VHS, and a background vignette.

Start with one effect at a moderate intensity. Add more only after checking the
result during normal desktop use, video playback, and fullscreen transitions.

## Reorder effects

The active-effect list is ordered front to back: item **1** is topmost. Moving
an effect changes its composition order immediately.

Order matters. A grain or CRT treatment above a light effect produces a
different result from placing it behind. There is no universally correct stack;
choose the one that keeps text and application content readable.

## Foreground versus background

Some effects can participate in a foreground overlay presentation. Foreground
effects can be visually stronger and may cost more to render. Keep them off
when you want ambience only behind shell content.

True fullscreen applications suppress Lacuna foreground effects on their
output.

## Performance guidance

- Add effects one at a time.
- Prefer lower intensity or count before combining many animated effects.
- Disable mouse reactivity for dust motes if it is distracting.
- Compare behavior on each monitor, especially mixed refresh rates or scales.
- If frame rate changes noticeably, disable the last effect and restart the
  shell before reporting a regression.

See [Known limitations](../help/known-limitations.md) for the beta support
boundary.
