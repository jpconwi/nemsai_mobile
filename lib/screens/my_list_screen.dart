/// my_list_screen.dart - My Reports (concerns + problems together) / Feedback / Reservations.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/record_form.dart';
import '../widgets/skeleton.dart';

const _longText = ['description', 'message', 'purpose', 'additional_info'];

class MyListScreen extends StatefulWidget {
  const MyListScreen({super.key, required this.kind});
  final String kind; // reports (concerns + problems) | feedback | reservations

  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  Map<String, dynamic>? _data;
  String _error = '';
  bool _open = false;
  Map<String, dynamic>? _result;
  String _q = '';
  String _recordFilter = 'all'; // all | concern | problem (My Reports only)
  String _formKind = 'report'; // concern | report (My Reports only)

  bool get _combined => widget.kind == 'reports';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final Map<String, dynamic> d;
      if (_combined) {
        final results = await Future.wait([api.get('/api/me/records/concerns'), api.get('/api/me/records/reports')]);
        d = _merge(Map<String, dynamic>.from(results[0] as Map), Map<String, dynamic>.from(results[1] as Map));
      } else {
        d = await api.get('/api/me/records/${widget.kind}');
      }
      if (mounted) {
        setState(() {
          _data = d;
          _error = '';
        });
      }
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// Concerns and problems in one list, newest first (same as the website's My Reports).
  Map<String, dynamic> _merge(Map<String, dynamic> concerns, Map<String, dynamic> reports) {
    List<Map<String, dynamic>> tag(Map<String, dynamic> src, String type) =>
        ((src['rows'] as List?) ?? const []).map((e) {
          final row = Map<String, dynamic>.from(e as Map);
          row['record_kind'] = type;
          row['record_category'] = '${row['concern_type'] ?? row['report_type'] ?? ''}';
          return row;
        }).toList();
    final rows = [...tag(concerns, 'concern'), ...tag(reports, 'problem')]
      ..sort((a, b) => '${b['created_at'] ?? ''}'.compareTo('${a['created_at'] ?? ''}'));
    return {
      'spec': {
        'title': 'My Reports',
        'intro': 'Submit and track campus concerns or problems.',
        'form': 'report',
        'image': true,
      },
      'rows': rows,
      'columns': [
        ['ID', 'id'],
        ['Submitted', 'created_at'],
        ['Type', 'record_category'],
        ['Location', 'location'],
        ['Description', 'description'],
        ['Status', 'status'],
      ],
      'image': true,
      'pdf': true,
    };
  }

  bool _matches(Map<String, dynamic> row) {
    if (_combined && _recordFilter != 'all' && row['record_kind'] != _recordFilter) return false;
    final words = _q.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return true;
    final text = row.values.where((v) => v is String || v is num).join(' ').toLowerCase();
    return words.every(text.contains);
  }

  void _done(Map<String, dynamic> res) {
    setState(() => _result = res);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      _load();
      setState(() {
        _open = false;
        _result = null;
      });
    });
  }

  Future<void> _showPhoto(String filename) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final Uint8List bytes = await api.bytes('/api/uploads/$filename');
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(child: Image.memory(bytes, fit: BoxFit.contain)),
        ),
      );
    } on ApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openPdf(Object? id, String kind) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await api.openPdf('/api/pdf/$kind/$id', '$kind-$id');
    } on ApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final spec = d == null ? null : Map<String, dynamic>.from(d['spec'] as Map);
    final title = spec?['title'] as String? ?? _fallbackTitle(widget.kind);

    Widget body;
    if (_error.isNotEmpty && d == null) {
      body = ListView(padding: const EdgeInsets.all(16), children: [
        EmptyState(
          title: 'Could not load this page',
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
    } else if (d == null) {
      body = const FormSkeleton();
    } else {
      body = _content(d, spec!);
    }

    return AppScaffold(
      title: title,
      current: '/${widget.kind}',
      body: body,
    );
  }

  String _fallbackTitle(String kind) => switch (kind) {
        'reports' => 'My Reports',
        'feedback' => 'Feedback',
        _ => 'Reservations',
      };

  Widget _content(Map<String, dynamic> d, Map<String, dynamic> spec) {
    final all = ((d['rows'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final columns = ((d['columns'] as List?) ?? const [])
        .map((c) => (c as List).map((e) => '$e').toList())
        .toList();
    final rows = all.where(_matches).toList();
    final form = _combined ? _formKind : spec['form'] as String;
    final hasImage = _combined ? d['image'] == true : spec['image'] == true;
    final hasPdf = d['pdf'] == true;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          PageTitle('${spec['title']}', intro: '${spec['intro']}'),
          FilledButton.icon(
            onPressed: () => setState(() => _open = !_open),
            icon: Icon(_open ? Icons.close : Icons.add),
            label: Text(_open ? 'Close form' : (_combined ? 'New report' : 'New $form')),
          ),
          if (_open) ...[
            const SizedBox(height: 14),
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_combined) ...[
                  DropdownButtonFormField<String>(
                    value: _formKind,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Submit as'),
                    items: const [
                      DropdownMenuItem(
                          value: 'concern',
                          child: Text('Concern - facility or service problem', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 'report',
                          child: Text('Problem - incident or safety/security issue', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _formKind = v ?? 'report'),
                  ),
                  const SizedBox(height: 14),
                ],
                RecordForm(key: ValueKey(form), kind: form, onSuccess: _done),
                if (_result != null) ...[
                  const SizedBox(height: 12),
                  SuccessCard(result: _result!),
                  const SizedBox(height: 4),
                  const Text('Reloading your list...', style: TextStyle(color: C.muted, fontSize: 13)),
                ],
              ]),
            ),
          ],
          const SizedBox(height: 22),
          const Text('Your submissions',
              style: TextStyle(fontFamily: serif, fontSize: 19, fontWeight: FontWeight.w700, color: C.blueDeep)),
          const SizedBox(height: 8),
          if (_combined) ...[
            DropdownButtonFormField<String>(
              value: _recordFilter,
              decoration: const InputDecoration(labelText: 'Filter by type'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All records')),
                DropdownMenuItem(value: 'concern', child: Text('Concerns')),
                DropdownMenuItem(value: 'problem', child: Text('Problems')),
              ],
              onChanged: (v) => setState(() => _recordFilter = v ?? 'all'),
            ),
            const SizedBox(height: 10),
          ],
          if (all.length > 4 || _q.isNotEmpty) ...[
            TextField(
              decoration: InputDecoration(
                hintText: 'Search your submissions...',
                prefixIcon: const Icon(Icons.search),
                suffixText: _q.isEmpty ? '${all.length} items' : '${rows.length} of ${all.length}',
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 10),
          ],
          if (rows.isNotEmpty)
            for (final r in rows) ...[
              _recordCard(r, columns, hasImage, hasPdf),
              const SizedBox(height: 10),
            ]
          else if ((_q.isNotEmpty || (_combined && _recordFilter != 'all')) && all.isNotEmpty)
            EmptyState(
                title: 'No matches',
                text: _q.isNotEmpty ? 'Nothing matches "$_q".' : 'You have no records of this type yet.')
          else
            EmptyState(
              title: 'Nothing yet',
              text: 'You have not submitted anything here yet.',
              action: FilledButton(onPressed: () => setState(() => _open = true), child: Text(_combined ? 'New report' : 'New $form')),
            ),
        ],
      ),
    );
  }

  Widget _recordCard(Map<String, dynamic> r, List<List<String>> columns, bool hasImage, bool hasPdf) {
    final status = columns.where((c) => c.length > 1 && c[1] == 'status').isEmpty ? null : '${r['status'] ?? ''}';
    final image = '${r['image_filename'] ?? ''}';
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('#${padId(r['id'])}', style: const TextStyle(fontWeight: FontWeight.w800, color: C.blueDeep)),
          if (r['record_kind'] != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: r['record_kind'] == 'concern' ? const Color(0xFFEDF3F8) : const Color(0xFFE3EDF5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(r['record_kind'] == 'concern' ? 'Concern' : 'Problem',
                  style: TextStyle(
                      color: r['record_kind'] == 'concern' ? const Color(0xFF3C5D78) : const Color(0xFF234F75),
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ],
          const Spacer(),
          if (status != null && status.isNotEmpty) StatusBadge(status),
        ]),
        const SizedBox(height: 8),
        for (final c in columns)
          if (c.length > 1 && c[1] != 'status' && c[1] != 'id' && '${r[c[1]] ?? ''}'.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 104, child: Text(c[0], style: const TextStyle(color: C.muted, fontSize: 13))),
                Expanded(
                  child: Text('${r[c[1]]}',
                      style: TextStyle(fontSize: _longText.contains(c[1]) ? 13.5 : 14.5, height: 1.35)),
                ),
              ]),
            ),
        if ((hasImage && image.isNotEmpty) || hasPdf) ...[
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            if (hasImage && image.isNotEmpty)
              TextButton.icon(
                onPressed: () => _showPhoto(image),
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('View photo'),
              ),
            if (hasPdf)
              TextButton.icon(
                onPressed: () => _openPdf(r['id'], r['record_kind'] == null ? widget.kind : (r['record_kind'] == 'concern' ? 'concerns' : 'reports')),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('PDF'),
              ),
          ]),
        ],
      ]),
    );
  }
}
