import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notification inbox shared by the QuickSalon customer and management apps.
/// The database trigger creates notifications; this screen only reads/acknowledges them.
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({
    super.key,
    required this.managementMode,
    this.highlightedNotificationId,
    this.appointmentId,
  });

  final bool managementMode;
  final String? highlightedNotificationId;
  final String? appointmentId;

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String? _shopId;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
  }

  Future<void> _load() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Please sign in to view notifications.';
        });
      }
      return;
    }

    try {
      dynamic response;
      if (widget.managementMode) {
        final profile = await _client
            .from('profiles')
            .select('shop_id,role')
            .eq('id', user.id)
            .maybeSingle();

        _shopId = profile?['shop_id']?.toString();

        if (_shopId == null || _shopId!.isEmpty) {
          throw Exception('No shop is assigned to this management account.');
        }

        response = await _client
            .from('notifications')
            .select(
                'id,event_key,title,body,data,is_read,created_at,appointment_id')
            .eq('recipient_shop_id', _shopId!)
            .order('created_at', ascending: false)
            .limit(100);
      } else {
        response = await _client
            .from('notifications')
            .select(
                'id,event_key,title,body,data,is_read,created_at,appointment_id')
            .eq('recipient_user_id', user.id)
            .order('created_at', ascending: false)
            .limit(100);
      }

      if (!mounted) return;

      final loadedItems = List<Map<String, dynamic>>.from(response);

      // When opened from a push, bring the related notification to the top.
      loadedItems.sort((a, b) {
        int rank(Map<String, dynamic> item) {
          if (widget.highlightedNotificationId != null &&
              item['id']?.toString() ==
                  widget.highlightedNotificationId) {
            return 0;
          }

          if (widget.appointmentId != null &&
              item['appointment_id']?.toString() ==
                  widget.appointmentId) {
            return 1;
          }

          return 2;
        }

        return rank(a).compareTo(rank(b));
      });

      setState(() {
        _items = loadedItems;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _subscribe() {
    _channel = _client
        .channel(
          'quicksalon-notifications-${widget.managementMode ? 'shop' : 'user'}-${_client.auth.currentUser?.id ?? 'signed-out'}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (_) {
            _load();
          },
        )
        .subscribe();
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    if (item['is_read'] == true) return;

    try {
      await _client.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', item['id']);

      if (mounted) {
        setState(() {
          item['is_read'] = true;
        });
      }
    } catch (_) {
      // RLS remains the authority; a failed acknowledgement does not break the inbox.
    }
  }

  Future<void> _markAllRead() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      var query = _client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('is_read', false);

      if (widget.managementMode) {
        if (_shopId == null) return;
        await query.eq('recipient_shop_id', _shopId!);
      } else {
        await query.eq('recipient_user_id', user.id);
      }

      await _load();
    } catch (_) {}
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      unawaited(_client.removeChannel(channel));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((item) => item['is_read'] != true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: _load,
                          child: const Text('Try again'),
                        ),
                      ),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        children: const [
                          SizedBox(height: 150),
                          Icon(Icons.notifications_none, size: 64),
                          SizedBox(height: 12),
                          Center(
                            child: Text('You are all caught up!'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final read = item['is_read'] == true;

                          DateTime? created;
                          try {
                            created = DateTime.parse(
                              item['created_at'].toString(),
                            ).toLocal();
                          } catch (_) {}

                          return Card(
                            elevation: read ? 0 : 1,
                            color: read
                                ? null
                                : Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(.35),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(
                                  _iconFor(
                                    item['event_key']?.toString() ?? '',
                                  ),
                                ),
                              ),
                              title: Text(
                                item['title']?.toString() ??
                                    'QuickSalon notification',
                                style: TextStyle(
                                  fontWeight: read
                                      ? FontWeight.normal
                                      : FontWeight.w700,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(item['body']?.toString() ?? ''),
                                    if (created != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 6),
                                        child: Text(
                                          '${created.day.toString().padLeft(2, '0')}/${created.month.toString().padLeft(2, '0')}/${created.year} • ${TimeOfDay.fromDateTime(created).format(context)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              onTap: () => _markRead(item),
                              trailing: read
                                  ? null
                                  : const Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: Colors.blue,
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  IconData _iconFor(String key) {
    if (key.contains('reminder')) return Icons.alarm;
    if (key.contains('cancel') || key.contains('reject')) {
      return Icons.event_busy;
    }
    if (key.contains('accepted') || key.contains('completed')) {
      return Icons.check_circle_outline;
    }
    if (key.contains('message')) return Icons.chat_bubble_outline;
    if (key.contains('booking')) return Icons.calendar_month_outlined;
    return Icons.notifications_outlined;
  }
}
