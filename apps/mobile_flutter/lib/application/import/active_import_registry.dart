/// In-process guard that distinguishes a currently-running import from a row
/// left behind by a process crash.
///
/// The registry is intentionally memory-only: after a real process restart it
/// is empty, so durable recovery can resolve every interrupted row.
class ActiveImportRegistry {
  ActiveImportRegistry._();

  static final Set<String> _ids = <String>{};

  static void register(String id) => _ids.add(id);

  static void unregister(String id) => _ids.remove(id);

  static bool contains(String id) => _ids.contains(id);
}
