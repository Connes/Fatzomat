import 'package:flutter/foundation.dart';

import '../app_exception.dart';

/// Small framework-neutral controller for feature state.
/// Keeps loading/error state out of widgets without introducing a heavy state package.
abstract class AsyncController<T> extends ChangeNotifier {
  T? _data;
  Object? _error;
  bool _loading = false;
  bool _disposed = false;
  int _loadGeneration = 0;

  T? get data => _data;
  Object? get error => _error;
  bool get loading => _loading;
  bool get hasData => _data != null;

  Future<void> load() async {
    if (_disposed) return;
    final generation = ++_loadGeneration;
    _loading = true;
    _error = null;
    if (!_disposed) notifyListeners();
    try {
      final result = await fetch();
      // A newer load may have started while this request was in flight.
      // Keep the newest request authoritative so a slow response cannot
      // overwrite fresher state.
      if (!_disposed && generation == _loadGeneration) {
        _data = result;
      }
    } catch (error) {
      if (!_disposed && generation == _loadGeneration) {
        _error = normalizeAppException(error);
      }
    } finally {
      if (!_disposed && generation == _loadGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<T?> refresh() async {
    await load();
    return _data;
  }

  Future<T?> fetch();
}
