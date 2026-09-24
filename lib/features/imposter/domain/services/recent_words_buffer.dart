import 'dart:collection';

/// Remembers the most recently dealt word ids, oldest first.
class RecentWordsBuffer {
  RecentWordsBuffer({required this.limit});

  final int limit;
  final Queue<String> _ids = Queue<String>();

  bool contains(String id) => _ids.contains(id);
  bool get isEmpty => _ids.isEmpty;
  int get length => _ids.length;
  Set<String> get ids => Set.unmodifiable(_ids);
  String? get mostRecent => _ids.isEmpty ? null : _ids.last;

  void add(String id) {
    _ids.remove(id);
    _ids.addLast(id);
    while (_ids.length > limit) {
      _ids.removeFirst();
    }
  }

  void dropOldest() {
    if (_ids.isNotEmpty) _ids.removeFirst();
  }

  void clear() => _ids.clear();
}
