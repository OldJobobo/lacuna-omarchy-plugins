# Lacuna Documentation Design Pass

Status: active — implemented locally; deployment validation pending

## Goal

Refine the published MkDocs site so it feels like a Lacuna surface rather than
a lightly themed Material site, while preserving the user-first information
architecture, factual content, accessibility, strict builds, and GitHub Pages
deployment.

This pass changes the documentation presentation only. It does not redesign the
Lacuna shell or alter QML, plugins, settings, installation behavior, release
claims, or support policy.

## Design Direction

The site should express Lacuna through **form rather than a fixed brand hue**:
mono-first typography, weighted negative space, visible seams, square joined
edges, restrained recess states, and one deliberate reveal.

The signature element will be an **attached shell specimen** on the homepage.
At desktop widths, the introduction and a real Lacuna screenshot form two
joined regions with a square attachment seam. On narrow screens they stack and
the attachment becomes horizontal. On first entry, the image region may reveal
from that seam over the canonical 300 ms curve, with its content disclosed only
after the geometry is substantially open. Reduced-motion users receive the
completed composition immediately.

Material continues to own navigation, search, article semantics, and responsive
shell behavior. Lacuna styling changes their visual relationships without
forking or replacing those systems.

## Current Findings

### Keep

- The user-first navigation and task journeys in `mkdocs.yml`.
- The homepage thesis, **The desktop lives in the seam.**
- Self-hosted Hack and Tektur fonts with no external font dependency.
- Light and dark modes without a fixed Lacuna brand color.
- Square controls, visible borders, local focus treatment, and reduced-motion
  support already present in `docs/assets/stylesheets/lacuna.css`.
- Material search, instant navigation, code copy, edit links, and deployment.
- The existing real product captures under `docs/screenshots/readme/`.

### Improve

1. The hero is one column at every width, so its largest branded area does not
   actually express an attached surface.
2. The mobile `h1` can reach approximately 55 px at 390 px wide and dominates
   the first viewport.
3. The beta compatibility warning is not itself actionable while a direct
   Installation action sits beside it.
4. The current wide hero capture makes the wallpaper more legible than the
   shell geometry at article and mobile sizes.
5. Long-form Hack body text is small and has no prose-specific measure distinct
   from code, tables, and figures.
6. Full-width rules on every `h2` create a repetitive ledger rather than a
   meaningful seam hierarchy.
7. The three homepage paths read as generic equal cards instead of one connected
   task assembly.
8. Navigation and buttons do not yet share a complete recess/edge interaction
   language.
9. Accessibility tests pin JavaScript strings but do not exercise behavior
   after Material instant navigation.

## Scope

### Must Have

- A shared documentation token layer for field, plate, void, ink, soft,
  whisper, seam, focus, recess, spacing, type, content width, and motion.
- A readable article system for prose, headings, lists, links, code, tables,
  tabs, details, admonitions, and figures.
- A responsive attached homepage hero with one primary onboarding action and an
  actionable compatibility path.
- A reusable screenshot specimen pattern with factual labels, captions, alt
  text, intrinsic dimensions, and a link to a larger source.
- Consistent header, navigation, table-of-contents, search, footer, button, and
  current-page states using seam, recess, and edge rather than hue alone.
- Behavioral verification for drawer and search keyboard access across initial
  load and instant navigation.
- Strict build, generated-link, responsive, contrast, zoom, reduced-motion, and
  GitHub Pages subpath validation.

### Optional Polish

- A small “See the shell” strip using purpose-made crops from current, real
  product screenshots.
- Print styles.
- Automated browser accessibility or screenshot comparison, if the maintenance
  cost is acceptable.
- Additional restrained reveal treatments where they clarify state.

Optional work must remain independently removable and cannot block the core
pass.

### Non-Goals

- Changing Lacuna shell geometry, motion, widgets, themes, or runtime behavior.
- Replacing MkDocs Material or creating a custom theme fork.
- Restructuring top-level navigation or rewriting the user journey.
- Introducing a JavaScript framework, remote fonts, analytics, or CDN assets.
- Publishing concept art, generated mockups, or temporary reference captures as
  current product UI.
- Recoloring product screenshots or assigning Lacuna a permanent brand accent.
- Cardifying every article section or adding ornamental gradients, glass, and
  stacked shadows.

## Implementation Plan

### Phase 0 — Freeze The Baseline

- [x] Build the current site with strict mode and run the generated-link check.
- [x] Capture the homepage plus representative prose, code, and table pages in
  light and dark modes at mobile and desktop widths.
- [x] Record the current navigation, URLs, CTA order, screenshot exclusions,
  local-font configuration, and Pages permissions as non-visual contracts.
- [x] Require a content diff review so presentation work cannot silently change
  versions, commands, compatibility claims, or support policy.

**Gate:** baseline checks pass and no shell or QML change is required.

### Phase 1 — Establish Documentation Tokens

Primary file: `docs/assets/stylesheets/lacuna.css`

- [x] Consolidate scheme values into semantic site roles based on the Lacuna
  vocabulary.
- [x] Add named scales for spacing, prose measure, wide content, type sizes,
  seams, focus, recess, and motion.
- [x] Keep Hack for body/chrome/code and reserve Tektur for headings and compact
  structural labels.
- [x] Raise normal prose to a 15–16 px equivalent with a 64–70 character measure
  and approximately 1.65 line height.
- [x] Keep code, tables, tabs, and figures free to use the wider article column.
- [x] Verify essential text, controls, and focus indicators in both schemes.

**Gate:** all custom components resolve through shared roles; no remote font or
component-specific hue is introduced.

### Phase 2 — Refine Global Chrome And Article Primitives

Primary file: `docs/assets/stylesheets/lacuna.css`

- [x] Apply the shared seam and recess language to the header, primary
  navigation, right table of contents, search, footer, edit/copy actions, and
  current-page indicators.
- [x] Preserve inline-link underlines and selection cues that do not rely on
  color alone.
- [x] Replace the repeated full-width `h2` rule with a shorter expressed seam
  and more deliberate vertical space.
- [x] Normalize headings, lists, blockquotes, buttons, code, tables, tabs,
  details, and admonitions.
- [x] Ensure long commands and wide tables scroll inside their own component
  without causing page-level horizontal scrolling.
- [x] Keep Material's stacking, sticky regions, search, drawer, and copy
  behavior intact.

**Gate:** representative long-form pages remain readable, navigable, and stable
at 200% zoom and narrow widths.

### Phase 3 — Recompose The Homepage

Files:

- `docs/index.md`
- `docs/assets/stylesheets/lacuna.css`

- [x] Build the attached shell specimen as a two-region composition at desktop
  widths and a stacked composition with a horizontal seam on mobile.
- [x] Keep source order semantic: heading, lede, release/compatibility status,
  primary action, then product image.
- [x] Make **Start here** the single primary action. Keep Installation secondary
  and make Compatibility directly reachable from the beta status.
- [x] Use the exact release string once and avoid competing beta labels.
- [x] Turn the three path cards into one connected task rail with action-led
  headings for installation, configuration, and recovery.
- [x] Add intrinsic image dimensions and preserve useful alt text.
- [x] If the hero reveal is implemented, animate geometry from the seam over
  300 ms using `cubic-bezier(0.20, 0, 0.32, 1)`; disclose image content after
  approximately 55% progress and render immediately under reduced motion.

**Gate:** the first viewport communicates product, beta safety, and the primary
next step without oversized type or bypassing compatibility guidance.

### Phase 4 — Build The Screenshot System

Files:

- `docs/index.md` and selected user guides
- `docs/assets/stylesheets/lacuna.css`
- New optimized images under `docs/screenshots/user/` if required

- [x] Define a reusable `lacuna-specimen` figure with an optional state label,
  factual caption, alt text, and full-size link.
- [x] Produce responsive crops from authentic public project captures for:
  shell overview, attached sidebar/flyout detail, and appearance/ambience.
- [x] Capture new real UI only when the existing public WebPs cannot show the
  required state clearly.
- [x] Keep original sources and record which live state each derivative shows.
- [x] Never promote `docs/screenshots/reference/09-*`, `10-*`, or generated
  concept imagery as current product truth.

**Gate:** at least three major user-facing states are legible at documentation
widths and include useful non-duplicative captions and alt text.

### Phase 5 — Harden Interaction And Accessibility

Files:

- `docs/assets/javascripts/accessibility.js`
- `tests/test_docs_contracts.py`
- Optional `tests/test_docs_accessibility.py`

- [x] Verify Enter and Space activation for Material's drawer and search labels.
- [x] Verify `aria-controls`, `aria-expanded`, and open/close accessible names
  remain synchronized.
- [x] Exercise repeated instant navigation and prevent stale observers or
  duplicate listeners.
- [x] Confirm Escape dismissal and focus recovery without replacing Material's
  state machine.
- [x] Ensure every interactive target is at least 44×44 CSS px where practical
  on touch layouts.
- [x] Use a contrast-safe focus treatment on field, plate, primary buttons,
  screenshot links, and search/drawer controls.
- [x] Verify reduced motion cannot leave reveal content hidden.

**Gate:** keyboard-only use remains complete before and after several
instant-navigation transitions.

### Phase 6 — Contracts, Visual Review, And Deployment

Files:

- `tests/test_docs_contracts.py`
- `tests/test_docs_links.py` only if link-checker cases change
- `mkdocs.yml` only if registering an approved asset or feature
- `.github/workflows/docs.yml` only if approved browser checks are added

- [x] Pin load-bearing token, font, focus, reduced-motion, responsive hero,
  screenshot exclusion, CTA-order, and accessibility-script contracts.
- [x] Preserve strict build, generated-link validation, least-privilege Pages
  permissions, and pull-request non-deployment.
- [x] Run the full visual matrix below and compare it with the baseline.
- [x] Review the final diff for factual drift and accidental publication of
  reference material.
- [ ] Publish to Pages and smoke-test the deployed `/lacuna-shell/` paths,
  assets, fragments, search, theme switch, and edit links.

**Gate:** all automated and manual completion criteria pass on the deployed
site.

## Local Implementation Checkpoint — 2026-08-04

Phases 0–5 and the local portions of Phase 6 are implemented. The baseline and
final matrices cover the homepage, installation, troubleshooting, color, and
geometry pages in light and dark schemes at mobile and desktop widths. The
final automated matrix additionally checks seven viewport widths, page-level
overflow, mobile heading size, prose size, and reduced-motion visibility.
Keyboard probes cover Enter, Space, Escape focus recovery, and repeated Material
instant-navigation enhancement. Screenshot derivative provenance is recorded in
`docs/screenshots/user/sources.json`.

The authentic source captures predate beta.3 and are labeled with their source
version rather than presented as current release evidence. Refreshing them is
not required for the represented shell states, but the deployment review should
replace any image whose visible UI has materially drifted.

The remaining gate is external: publish the reviewed commit and smoke-test the
actual GitHub Pages `/lacuna-shell/` deployment. The repository-wide check is
also currently blocked by host compatibility and vendored `BarModel.js` drift
that predates and is outside this presentation-only pass; focused documentation
checks, strict MkDocs, generated links, and the AUR scaffold check pass locally.

## Expected Files

### Likely Modified

- `docs/assets/stylesheets/lacuna.css`
- `docs/index.md`
- `docs/assets/javascripts/accessibility.js`
- selected user guides that receive factual screenshots
- `tests/test_docs_contracts.py`

### Conditional

- `tests/test_docs_accessibility.py`
- `tests/test_docs_links.py`
- `mkdocs.yml`
- `.github/workflows/docs.yml`
- optimized authentic captures under `docs/screenshots/user/`

### Design Authorities, Not Edit Targets

- `docs/lacuna-design-system/00-philosophy.md`
- `docs/lacuna-design-system/01-color.md`
- `docs/lacuna-design-system/02-geometry.md`
- `docs/lacuna-design-system/03-motion.md`
- `docs/lacuna-design-system/04-typography.md`
- `docs/lacuna-design-system/05-components.md`

## Visual And Accessibility Matrix

| Surface | Viewports | Required states |
| --- | --- | --- |
| Homepage | 320×568, 390×844, 768×1024, 1024×768, 1440×900 | Light, dark, keyboard focus, reduced motion, slow image load |
| Installation | 390×844, 1024×768, 1440×900 | Long commands, code copy, navigation, light/dark |
| Troubleshooting | 390×844, 1440×900 | Dense headings, TOC, search navigation |
| Color specification | 320×568, 768×1024, 1440×900 | Wide table overflow, links, light/dark |
| Geometry specification | 320×568, 1440×900 | Diagrams, code, anchors, narrow reflow |
| Global chrome | Mobile and desktop | Drawer, search, theme switch, active nav, footer, instant navigation |
| Accessibility | 390×844, 1440×900 | Keyboard only, 200% zoom, reduced motion, visible focus |
| GitHub Pages | Representative mobile/desktop | `/lacuna-shell/` assets, fragments, search, and edit links |

## Automated Checks

```bash
python3 -m pytest tests/test_docs_contracts.py tests/test_docs_links.py tests/test_docs_accessibility.py
mkdocs build --strict --site-dir site
python3 scripts/check_docs_links.py site --site-prefix /lacuna-shell/
git diff --check
./scripts/check.sh
```

If browser automation is added, it must cover the keyboard enhancement and
responsive hero without replacing the manual review matrix.

## Completion Criteria

- At 960 px and wider, the hero reads as two joined regions; at 768 px and below
  it stacks with one horizontal seam.
- No page-level horizontal overflow occurs at 320, 360, 390, 768, 1024, or
  1440 px widths.
- Mobile `h1` remains at or below 42 px at a 390 px viewport.
- Normal prose computes to at least 15 px, remains within 64–70 characters, and
  keeps a 1.6–1.7 line height.
- The first decision area presents the exact release, a direct Compatibility
  link, and one visually primary **Start here** action.
- The hero has no more than one orchestrated reveal; reduced motion reaches the
  final visible state immediately.
- At least three authentic user-facing product states are clear at article and
  mobile widths and carry useful alt text and captions.
- Navigation, buttons, tabs, details, search results, edit/copy controls, and
  task links have clear rest, hover, pressed, focus, and current states.
- Essential text meets WCAG 2.2 AA; meaningful focus and control boundaries
  reach 3:1 against adjacent colors.
- Keyboard testing covers skip-to-content, drawer, search, theme switch,
  primary action, task rail, TOC, code copy, edit link, details, and footer.
- At 200% zoom, focused content is not obscured and only intentionally wide
  components scroll horizontally.
- Local fonts, search, CSS, JavaScript, images, internal links, and fragments
  load correctly from the GitHub Pages subpath.
- Strict MkDocs, generated links, focused docs tests, the repository check, and
  the deployment workflow all pass.
- The final diff contains no QML/runtime changes, navigation restructuring,
  release-truth drift, remote dependencies, or reference-concept publication.

## Risks And Controls

- **Material DOM coupling:** keep selectors narrow and test against the pinned
  dependency before changing markup or JavaScript behavior.
- **Instant-navigation duplication:** make enhancement idempotent and exercise
  several transitions in one browser session.
- **Monospace fatigue:** validate long procedural pages, not only the homepage.
- **Translucent contrast:** decorative seams may be subtle; essential text,
  control edges, and focus cannot inherit their low contrast.
- **Screenshot drift:** record capture state and refresh user images when the UI
  they document materially changes.
- **Visual-test noise:** keep automated screenshot comparison optional until its
  ownership and update policy are explicit.
- **Design-language overreach:** use shell geometry as a principle, not as a
  literal HTML recreation.
