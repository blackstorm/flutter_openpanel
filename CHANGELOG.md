## 0.4.0

- Fix JSON `/track` responses (no more `as String` crash; #4 / PR #6).
- Drop unused deps: `dio`, `dio_smart_retry`, `equatable`, `logger`, `uuid`, `meta`.
- Use `http` with small retry loop.
- Persist analytics state only when it changes (not on every event).
- Collect package/device info once for both UA and properties.
- Load install referrer once.
- Remove vendored `example/` from the maintained fork.

## 0.3.0

- Upstream release baseline before this fork.
