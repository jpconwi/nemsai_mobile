/// notifications_screen.dart - current announcements from the administration (port of Notifications.jsx).
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';

/// One announcement (used here and on the Home screen).
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key, required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final category = '${item['category'] ?? ''}';
    final start = '${item['start_date'] ?? ''}';
    final end = '${item['end_date'] ?? ''}';
    final dates = [if (start.isNotEmpty) 'Date: $start', if (end.isNotEmpty) 'Until: $end'].join(' · ');
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text('${item['title'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: C.blueDeep)),
          ),
          if (category.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFE5EFF5), borderRadius: BorderRadius.circular(999)),
              child: Text(category, style: const TextStyle(color: C.blueDeep, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ]),
        const SizedBox(height: 6),
        Text('${item['body'] ?? ''}', style: const TextStyle(height: 1.4, fontSize: 14)),
        if (dates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(dates, style: const TextStyle(color: C.muted, fontSize: 12.5)),
          ),
      ]),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>>? _rows; // null = still loading
  String _error = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await api.get('/api/announcements');
      final rows = ((d['rows'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (mounted) {
        setState(() {
          _rows = rows;
          _error = '';
        });
      }
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    Widget body;
    if (rows == null && _error.isNotEmpty) {
      body = ListView(padding: const EdgeInsets.all(16), children: [
        EmptyState(
          title: 'Could not load notifications',
          text: _error,
          icon: Icons.cloud_off_outlined,
          action: FilledButton(
            onPressed: () {
              setState(() => _error = '');
              _load();
            },
            child: const Text('Try again'),
          ),
        ),
      ]);
    } else if (rows == null) {
      body = const FormSkeleton();
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            PageTitle('Notifications',
                intro: 'Current announcements from the administration. This list refreshes automatically.'),
            if (rows.isEmpty)
              EmptyState(
                title: "You're all caught up",
                text: 'There are no current announcements.',
                icon: Icons.notifications_none,
              )
            else
              for (final r in rows) ...[
                AnnouncementCard(item: r),
                const SizedBox(height: 10),
              ],
          ],
        ),
      );
    }
    return AppScaffold(title: 'Notifications', current: '/notifications', body: body);
  }
}
