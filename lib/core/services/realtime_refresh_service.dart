import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeRefreshController {
  RealtimeRefreshController({
    required SupabaseClient client,
    required String channelName,
    required VoidCallback onRefresh,
    Duration debounce = const Duration(milliseconds: 450),
  }) : _client = client,
       _onRefresh = onRefresh,
       _debounce = debounce,
       _channel = client.channel(channelName);

  final SupabaseClient _client;
  final VoidCallback _onRefresh;
  final Duration _debounce;
  final RealtimeChannel _channel;
  Timer? _timer;
  bool _subscribed = false;

  RealtimeRefreshController watchTable(
    String table, {
    PostgresChangeFilter? filter,
  }) {
    _channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      filter: filter,
      callback: (_) => _scheduleRefresh(),
    );
    return this;
  }

  void subscribe() {
    if (_subscribed) return;
    _channel.subscribe();
    _subscribed = true;
  }

  Future<void> dispose() async {
    _timer?.cancel();
    if (_subscribed) {
      await _client.removeChannel(_channel);
    }
  }

  void _scheduleRefresh() {
    _timer?.cancel();
    _timer = Timer(_debounce, _onRefresh);
  }
}
