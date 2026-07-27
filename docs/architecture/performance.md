# Performance Ownership And Measurement

Lacuna performance work is measurement-gated. The checked harness is
`scripts/lacuna-performance-benchmark`; release defaults use a 60-second warmup
and five 120-second samples. `--quick` validates the harness only and marks its
output non-promotable.

The harness records the shell process, monitor scales, configuration hashes,
raw samples, median, p95, process launches observed through `/proc`, CPU, RSS,
wakeups, descendant count, and zombies. Unsupported compositor/Qt frame timing
and disruptive startup/cycle measurements are reported explicitly rather than
replaced with misleading proxies. Target-specific artifacts live in
`docs/benchmarks/`.

## Polling ownership

- `lacuna.system-stats/Service.qml` is the sole subprocess snapshot owner. Bar
  widgets subscribe as output-local consumers; polling stops at zero consumers.
  `/proc/stat` and `/proc/meminfo` are read centrally, and the snapshot's
  `rootFilesystem` replaces the former duplicate `df` path.
- Canonical settings persistence uses `FileView.watchChanges` and atomic writes.
  It has no settled subprocess poll. The prior three-second target was already
  superseded by Phase 4.
- Shell settings keep broad startup and 60-second reconciliation reads, while
  action verification requests only affected domains. Partial results merge at
  top level without discarding unrelated state.
- `lacuna.screen-recording/Service.qml` is the settled polling authority.
  Dedicated and grouped widgets poll only as an unavailable-service fallback.
- Stopped media unloads the inline Qt `MediaPlayer`; background players remain
  only through the required black-cover exit transition and are destroyed when
  that transition settles. The persistent Python media worker is a control
  worker, not a decoder.

## Phase 6 evidence

The 60-second same-session system-stats samples recorded 33 observed snapshot
launches before deployment and 11 afterward, a 66.7% reduction. Broad shell CPU
and RSS improved in those samples rather than regressing. The launch observer
can miss very short children, so raw commands and service-owned launch counters
remain part of the evidence.

Five shell-settings samples measured a 310.2 ms full-refresh median versus
74.0 ms for toggles, 67.7 ms for Hyprland state, and 50.9 ms for monitor state.
Common actions therefore avoid the full collector and reduce verification time
by roughly 76–84%.

A 100-cycle menu open/close probe ended with the same descendant count as it
started and no zombies. Settled stopped-media diagnostics reported no mpv,
zero background Qt multimedia players, and no command or cleanup helper in
flight.
