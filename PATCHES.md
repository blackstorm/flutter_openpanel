# Patches (blackstorm/flutter_openpanel)

Fork of [stevenosse/openpanel_flutter](https://github.com/stevenosse/openpanel_flutter).

## 0.4.0

1. **JSON track response** — never cast body to `String` (PR #6 / issue #4).
2. **Persist on mutate only** — events no longer rewrite SharedPreferences.
3. **Deps** — `http` instead of Dio stack; drop equatable/logger/uuid.
4. **Device context** — one pass for UA + properties.
5. **Referrer** — fetch once.
6. **ASCII User-Agent** — `openpanel-flutter/<sdkVersion> (platform; model)`.
7. **Anonymous by default** — no random profileId; omit null profileId on track;
   [identify] binds internal UID only.
8. **No personal device names** — iOS never uses `ios.name`; Windows never uses
   `computerName`.
