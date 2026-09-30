import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Observable network state used by the UI and repositories.
/// Connectivity is only a hint; requests must still handle timeouts/errors.
enum NetworkStatus { online, offline, unknown }

class NetworkStatusService {
  final Connectivity _connectivity;
  final ValueNotifier<NetworkStatus> status = ValueNotifier(NetworkStatus.unknown);
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkStatusService({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  Future<void> start() async {
    status.value = _toStatus(await _connectivity.checkConnectivity());
    await _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      status.value = _toStatus(results);
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    status.dispose();
  }

  static NetworkStatus _toStatus(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none)
          ? NetworkStatus.online
          : NetworkStatus.offline;
}
