import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports device connectivity.
///
/// A thin abstraction over `connectivity_plus` so repositories can guard
/// network calls and code can be tested with a fake. Note: connectivity only
/// tells us the device *has* a network interface, not that the internet is
/// actually reachable — treat it as a fast pre-check, not a guarantee.
abstract interface class NetworkInfo {
  /// Whether the device currently has any active network connection.
  Future<bool> get isConnected;

  /// Stream of connectivity changes.
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  @override
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_isConnected);

  bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
