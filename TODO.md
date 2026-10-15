# Remaining work

- [ ] Test physical keyboard/mouse input, gamepad mappings, and removal behavior.
- [ ] Test real-device audio and latency, window policy, cursor/clipboard/drop behavior, and display scaling.
- [ ] Test text appearance, renderer resets, and state restoration on accelerated renderers. Recheck the [output-size discrepancy](docs/rendering.md#output-dimensions).
- [ ] Measure full frames on target hardware. Consider bulk vertex updates only if vertex preparation dominates.
- [ ] Test the [minimum supported native versions](docs/build.md#requirements).
- [ ] Pin a tested pack collection and automate clean builds.
- [ ] Test an installed application outside the checkout, including native library deployment.
