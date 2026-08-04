# Frequently asked questions

Status: user guide for the latest beta

## Is Lacuna a separate shell?

No. Lacuna runs as plugins inside Omarchy's existing Quickshell process. Do not
start another Quickshell instance for it.

## Does Lacuna replace Omarchy?

No. Omarchy remains the owner of the session, themes, system services, package
workflow, and shell host. Lacuna provides a custom connected presentation and
selected workflows on top.

## Why is the Lacuna bar opaque?

The bar, frame, sidebar, connectors, and flyouts are designed as one surface.
Transparency would break that structural connection, so the stock bar's
transparency behavior is not part of Lacuna's bar.

## Which installer option should I choose?

Choose **Full Lacuna install** unless you are developing, recovering, or
intentionally assembling an a-la-carte setup.

## Does installing the AUR package immediately change my desktop?

No. The package installs an immutable payload and the `lacuna-shell` command.
Run the guided installer to preview and apply the shell for your user.

## Can I use my existing Omarchy theme?

Yes. Theme owns hue; Lacuna follows the active Omarchy palette. Lacuna Settings
controls form, presentation, and its semantic/colorful profile.

## Why did a widget disappear on a narrow screen?

The responsive bar hides lower-priority whole widgets before sections overlap.
They return when space becomes available. The current layout remains stored.

## Why is there a second bar on my portrait monitor?

Portrait split is enabled by default for top or bottom bars. It moves selected
status widgets to a companion band on the opposite edge. You can disable the
advanced `barPresentation.portraitSplit` setting.

## Do media providers require credentials?

Not for the shell to load. Provider-specific features may require network
access, local commands, or credentials. Jellyfin needs configured server/account
details; YouTube can use public resolution with optional authentication
fallbacks.

## What does safe reset delete?

Safe reset restores Lacuna-owned presentation defaults and canonical
activation. It does not purge credentials, provider settings, Media Player
state, preferred/custom applications, reminders, unrelated Omarchy entries, or
unknown JSON-safe fields outside its ownership contract.

## How do I return to the stock bar?

Run `omarchy bar reset`. Use `omarchy bar defaults` only when you also intend to
restore Omarchy's packaged bar layout.
