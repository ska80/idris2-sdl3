# Development plan

Keep the bindings thin and keep native storage reusable. Use separate packages for SDL extensions.
Do not add widgets, a scene graph, action mapping, or game-loop policy to the binding.
Each change needs tests, ownership documentation, and a Chez build.

## Remaining work

- [ ] Test physical keyboard/mouse input, real gamepad mappings, and device removal. Synthetic
      events do not establish hardware behavior.
- [ ] Test text appearance, renderer resets, and state restoration on accelerated renderers. Recheck
      the documented SDL software-renderer output-size discrepancy.
- [ ] Measure full frames on target hardware. Evaluate bulk vertex updates if per-vertex preparation
      dominates the application workload.
- [ ] Test minimum supported SDL and extension versions. Current tests use SDL 3.4.16, Image 3.4.6,
      TTF 3.2.2, and Mixer 3.2.4.
- [ ] Pin a tested pack collection and automate clean builds. Test an installed application outside
      the checkout, including native library deployment.

Real-device audio, display behavior, latency, and accelerated-renderer performance remain separate
from dummy-driver tests.
