# Lacuna User Documentation

Status: active — foundation and MVP user journey in progress

## Goal

Create a first-class documentation product for people who use Lacuna, while
keeping architecture, design, contributor workflow, and project history
available without making them part of the normal user journey.

The documentation should let a new Omarchy user answer, in order:

1. What does Lacuna change?
2. Can I run it on my system?
3. How do I install and verify it?
4. Where are its main controls?
5. How do I customize, update, recover, or remove it?
6. Where do I get help?

## Approved Direction

- Build with MkDocs Material and publish through GitHub Pages.
- Optimize for the complete Lacuna shell; keep a-la-carte plugin installation
  as an advanced workflow.
- Document the latest release plus migration notes. Add fully versioned docs
  only after `1.0`.
- Treat `CHANGELOG.md` as canonical release history; GitHub Releases presents
  the same information.
- Retain plans and historical evidence in the repository, but exclude them
  from primary navigation and site search.
- Carry Lacuna's identity through mono typography, negative space, expressed
  seams, and restrained motion rather than a fixed brand hue.

## Source Of Truth

| User-facing fact | Authority |
| --- | --- |
| Current suite version | `VERSION` |
| Release history and known release limitations | `CHANGELOG.md` |
| Installer commands and flags | `scripts/lacuna` and its `--help` output |
| Source-bootstrap behavior and dependencies | `install.sh` |
| Normal installation, activation, layout, and reset ownership | `config/omakase-profile.json` |
| Plugin identity, stability, requirements, and widget options | `lacuna.*/manifest.json` |
| Packaged payload behavior | `packaging/aur/PKGBUILD` and packaging checks |
| Reviewed host version | `config/quattro-compatibility.json` |
| Runtime state defaults | `config/settings.example.json` |
| Safety and recovery guarantees | Installer implementation plus `tests/test_lacuna_installer.py` |

User pages summarize those authorities. They must not become independent
sources for generated counts, flags, or defaults.

## Information Architecture

### Use Lacuna

- Product landing page
- Getting started: requirements, installation, first run, upgrading
- Guides: sidebar, bar, appearance, media, ambience, and multiple monitors
- Configuration: Lacuna Settings, Omarchy Settings, advanced state files
- Operations: reset, recovery, uninstall, stock Omarchy restoration
- Help: troubleshooting, compatibility, known limitations, FAQ, support
- Releases: changelog entry point and migration notes

### Build Lacuna

Existing architecture, design-system, plugin, development, and contribution
references remain available from the documentation portal. They are secondary
to the user journey.

### Project History

Plans, benchmarks, announcements, reviews, and historical evidence stay in the
repository. They are intentionally omitted from the published navigation.

## Migration Map

| Current document | Disposition |
| --- | --- |
| `README.md` | Rewrite as a concise product storefront. |
| `docs/README.md` | Rewrite as an audience portal. |
| `docs/install.md` | Preserve as a compatibility entry point to canonical task guides. |
| `docs/configuration.md` | Preserve as a compatibility entry point to the new configuration section. |
| `docs/development/troubleshooting.md` | Keep developer-specific diagnostics; create separate user troubleshooting. |
| `docs/plugins/*` | Keep advanced inventory/contract references; explain features in user guides. |
| `docs/architecture/*` | Keep as technical authority outside primary user navigation. |
| `docs/lacuna-design-system/*` | Keep as design authority outside primary user navigation. |
| `docs/plans/*` | Keep as project evidence outside published navigation. |
| `docs/discord-beta-announcement.md` | Move to `docs/project/historical/` and label as beta.2 publication copy. |
| `docs/lacuna-suite-polish-review.md` | Move to `docs/project/historical/` and mark as historical review. |
| `CHANGELOG.md` | Keep as canonical release history and link from the release section. |

## Delivery Phases

### Phase 1 — Truth And Boundaries

- [x] Define user, developer, and historical audiences.
- [x] Record machine-readable authorities for current facts.
- [x] Correct current beta and AUR guidance in user-facing content.
- [x] Separate stale publication copy from current documentation.
- [ ] Generate repeated plugin/settings reference facts from source metadata.

### Phase 2 — Documentation Product Foundation

- [x] Add MkDocs Material configuration and pinned build dependencies.
- [x] Add a Lacuna-specific, accessible visual treatment.
- [x] Add GitHub Pages build/deploy workflow.
- [x] Establish user-first navigation and a concise repository storefront.
- [ ] Confirm the final public Pages URL and optional custom domain.

### Phase 3 — Essential User Journey

- [x] Publish requirements, installation, first-run, and upgrade guides.
- [x] Publish configuration ownership and common customization guides.
- [x] Publish reset, recovery, uninstall, compatibility, and support guides.
- [x] Publish current-release and migration entry points.
- [ ] Run a fresh-machine documentation walkthrough with a beta tester.

### Phase 4 — Feature Depth

- [x] Add guides for the sidebar, bar, appearance, media, ambience, and monitors.
- [ ] Add manifest-generated widget option reference.
- [ ] Add provider-specific walkthroughs after live validation.
- [ ] Add annotated screenshots for each major settings section.

### Phase 5 — Maintenance And Versioning

- [ ] Generate release/plugin facts during the release workflow.
- [ ] Add docs-link and command-example checks to the main gate.
- [ ] Define post-`1.0` documentation versioning and retention.
- [ ] Add a release checklist item for screenshots and known limitations.

## Documentation Quality Gates

- `mkdocs build --strict` succeeds without warnings.
- Every navigation target exists and every internal link resolves.
- `tests/test_docs_contracts.py` verifies the required user journey.
- Current user pages contain no obsolete beta or AUR-unavailable claims.
- Commands match `scripts/lacuna --help` and distinguish package from source
  invocation.
- Configuration pages distinguish UI settings, Omarchy-owned composition, and
  advanced state files.
- Screenshots represent real product UI and include useful alt text.
- Pages remain usable on narrow screens and with keyboard-only navigation.
- Visible focus meets contrast requirements and optional motion respects
  `prefers-reduced-motion`.
- Plans, benchmarks, and historical artifacts do not enter primary site
  navigation.

## Acceptance Criteria

- A new user can reach installation from the repository root in one click and
  verify the result without reading development documentation.
- A user can identify whether a setting belongs to Lacuna Settings or Omarchy
  Settings.
- Package and source users have distinct, safe update instructions.
- Recovery documentation explains `status`, safe reset, stock-bar restoration,
  uninstall, and state retention without requiring architecture knowledge.
- Compatibility guidance distinguishes a reviewed environment from an
  unsupported minimum-version promise.
- Release documentation points to `CHANGELOG.md` as authority.
- The site builds strictly and the repository documentation contracts pass.

## Non-Goals For This Milestone

- Documenting every internal plugin as a standalone product.
- Promising minimum Omarchy or Quickshell versions that have not been tested.
- Adding runtime behavior or new settings to match documentation.
- Publishing versioned documentation before the stable release line.
- Turning historical plans into current product guidance.
