/// home_screen.dart - the student / instructor dashboard (port of Home.jsx).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/auth_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';
import 'notifications_screen.dart';

String _greeting() {
  final h = DateTime.now().hour;
  return h < 12 ? 'Good morning' : (h < 18 ? 'Good afternoon' : 'Good evening');
}

class _Tile {
  const _Tile(this.path, this.title, this.text, this.icon, this.tone,
      {this.track = false, this.countKeys = const [], this.wide = false});
  final String path;
  final String title;
  final String text;
  final IconData icon;
  final Color tone;
  final bool track;
  final List<String> countKeys; // pending counts that are added together
  final bool wide;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _counts; // null = still loading
  List<Map<String, dynamic>> _announcements = const [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _loadAnnouncements();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _loadAnnouncements());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await api.get('/api/home');
      if (mounted) setState(() => _counts = Map<String, dynamic>.from(d['counts'] as Map? ?? {}));
    } on ApiError {
      if (mounted) setState(() => _counts = {'concerns': 0, 'reports': 0, 'reservations': 0});
    }
  }

  Future<void> _loadAnnouncements() async {
    try {
      final d = await api.get('/api/announcements');
      final rows = ((d['rows'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (mounted) setState(() => _announcements = rows);
    } on ApiError {
      // keep what is already shown
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user!;
    final instructor = user.isInstructor;

    final tiles = <_Tile>[
      const _Tile('/ai', 'NEMSAI Assistant', 'Ask about rooms, facilities, locations and instructors. You can type or send a photo.',
          Icons.chat_bubble_outline, Color(0xFF28699E), wide: true),
      const _Tile('/reports', 'My Reports', 'Submit and track concerns or problems.', Icons.description_outlined,
          Color(0xFF0F6B6B), track: true, countKeys: ['concerns', 'reports']),
      const _Tile('/feedback', 'Feedback', 'Share your thoughts about a campus area.', Icons.rate_review_outlined,
          Color(0xFF287FCB)),
      if (instructor) ...const [
        _Tile('/reservations', 'Reservations', 'Request a room or facility.', Icons.event_available_outlined,
            Color(0xFF1B6A25), track: true, countKeys: ['reservations']),
        _Tile('/faculty', 'Faculty Availability', 'Report an absence or mark yourself available.', Icons.school_outlined,
            Color(0xFF28699E)),
      ],
      const _Tile('/profile', 'Profile', 'Your account details.', Icons.person_outline, Color(0xFF456B8C)),
    ];

    return AppScaffold(
      title: 'NEMSAI',
      current: '/',
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _counts = null);
          await Future.wait([_load(), _loadAnnouncements()]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _hero(user),
            const SizedBox(height: 16),
            _announcementsPanel(),
            const SizedBox(height: 16),
            for (final t in tiles) ...[
              _tile(t),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hero(AppUser user) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
        decoration: BoxDecoration(
          color: C.blueDeep,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_greeting().toUpperCase(),
                  style: const TextStyle(color: Color(0xFFE6F5FF), fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 12)),
              const SizedBox(height: 6),
              Text('Welcome, ${user.firstName}',
                  style: const TextStyle(color: Colors.white, fontFamily: serif, fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('What would you like to do today?', style: TextStyle(color: Color(0xFFD7EAFF))),
              const SizedBox(height: 16),
              Wrap(spacing: 10, runSpacing: 10, children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: C.blueDeep),
                  onPressed: () => goTo(context, '/ai'),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Ask NEMSAI Assistant'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                  onPressed: () => goTo(context, '/reports'),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Report a problem'),
                ),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          const Opacity(opacity: 0.9, child: AppLogo(size: 64)),
        ]),
      );

  Widget _announcementsPanel() {
    final shown = _announcements.take(3).toList();
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Campus announcements',
                  style: TextStyle(fontFamily: serif, fontSize: 18, fontWeight: FontWeight.w700, color: C.blueDeep)),
              SizedBox(height: 2),
              Text('Updates from the administration.', style: TextStyle(color: C.muted, fontSize: 13)),
            ]),
          ),
          if (_announcements.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFE5EFF5), borderRadius: BorderRadius.circular(999)),
              child: Text('${_announcements.length} active',
                  style: const TextStyle(color: C.blueDeep, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
        ]),
        const SizedBox(height: 12),
        if (shown.isEmpty)
          const Text('There are no current announcements.', style: TextStyle(color: C.muted))
        else ...[
          for (final a in shown) ...[
            AnnouncementCard(item: a),
            const SizedBox(height: 8),
          ],
          if (_announcements.length > shown.length)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => goTo(context, '/notifications'),
                child: Text('View all ${_announcements.length} notifications'),
              ),
            ),
        ],
      ]),
    );
  }

  Widget _tile(_Tile t) {
    final pending = t.countKeys.fold<int>(0, (sum, k) => sum + ((_counts?[k] as num?)?.toInt() ?? 0));
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => goTo(context, t.path),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.line),
          ),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: t.tone.withOpacity(0.12), borderRadius: BorderRadius.circular(13)),
              child: Icon(t.icon, color: t.tone, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: C.blueDeep)),
                const SizedBox(height: 2),
                Text(t.text, style: const TextStyle(color: C.muted, fontSize: 13.5, height: 1.35)),
              ]),
            ),
            const SizedBox(width: 8),
            if (t.track && _counts == null)
              const Shimmer(child: Sk(h: 20, w: 62, r: 999))
            else if (pending > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFE3EDF5), borderRadius: BorderRadius.circular(999)),
                child: Text('$pending pending',
                    style: const TextStyle(color: Color(0xFF234F75), fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            const Icon(Icons.chevron_right, color: C.muted),
          ]),
        ),
      ),
    );
  }
}
