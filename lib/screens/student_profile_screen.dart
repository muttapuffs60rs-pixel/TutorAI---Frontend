import 'package:flutter/material.dart';
import '../services/student_profile_store.dart';
import '../widgets/usage_meter.dart';
import 'board_selection_screen.dart';
import 'chat_screen.dart';
import 'subscription_screen.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class StudentProfileScreen extends StatefulWidget {
  final StudentProfileStore? store;
  final Future<Map<String, dynamic>> Function()? loadUsage;
  const StudentProfileScreen({super.key, this.store, this.loadUsage});
  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late final StudentProfileStore _store =
      widget.store ?? SupabaseStudentProfileStore();
  Map<String, dynamic>? _account;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final account = await _store.account();
      if (mounted) setState(() => _account = account);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not load your profile. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _EditProfileScreen(account: _account!, store: _store),
      ),
    );
    if (saved == true && mounted) _load();
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Not available';
    final ist = date.toUtc().add(const Duration(hours: 5, minutes: 30));
    return '${ist.day} ${_months[ist.month - 1]} ${ist.year}';
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;
    final expiry = DateTime.tryParse(
      account?['subscription_expires_at']?.toString() ?? '',
    );
    final tier = account?['subscription_tier'] ?? 'free';
    final expired =
        tier != 'free' && expiry != null && !expiry.isAfter(DateTime.now());
    final plan =
        const {
          'free': 'Free',
          'tier_199': 'Standard',
          'tier_499': 'Syllabus Master',
          'tier_999': 'Premium',
          'admin': 'Admin',
        }[tier] ??
        'Learning';
    final birthday = validBirthDate(account?['date_of_birth']);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My profile'),
          actions: [
            IconButton(
              tooltip: 'Refresh profile',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Learning'),
              Tab(text: 'Credits'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Retry profile'),
                    ),
                  ],
                ),
              )
            : TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _card([
                        const Icon(Icons.account_circle_outlined, size: 56),
                        const SizedBox(height: 12),
                        Text(
                          account!['name'] as String,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SelectableText(account['email'] as String),
                        const SizedBox(height: 8),
                        Text('Joined ${_date(account['joined_at'])}'),
                        Text(
                          birthday != null
                              ? 'Date of birth: ${birthday.day} ${_months[birthday.month - 1]} ${birthday.year}'
                              : 'Date of birth: Not added (optional)',
                        ),
                        TextButton.icon(
                          onPressed: _edit,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit profile'),
                        ),
                      ]),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.school_outlined),
                          title: const Text('Board & curriculum'),
                          subtitle: Text(
                            boardNames[account['board']] ?? 'Select your board',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BoardSelectionScreen(
                                  changing: true,
                                  initialBoard: account['board'] as String?,
                                  onSave: (board) async {
                                    await _store.saveBoard(board);
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                              ),
                            );
                            if (mounted) _load();
                          },
                        ),
                      ),
                      _card([
                        Text(
                          expired ? '$plan · Expired' : '$plan plan',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (tier != 'free' &&
                            account['subscription_start_date'] != null)
                          Text(
                            'Started ${_date(account['subscription_start_date'])}',
                          ),
                        if (tier != 'free' && expiry != null)
                          Text(
                            '${expired ? 'Expired' : 'Valid until'} ${_date(expiry.toIso8601String())}',
                          ),
                        TextButton(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SubscriptionScreen(),
                              ),
                            );
                            if (mounted) _load();
                          },
                          child: Text(
                            expired ? 'Renew subscription' : 'View plans',
                          ),
                        ),
                        const Text(
                          'This shows your current subscription. A complete payment history is not available yet.',
                        ),
                      ]),
                      _card(const [
                        Text(
                          'Referrals & rewards',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Planned feature. Referral earnings and reward history will appear here once referrals are available.',
                        ),
                      ]),
                    ],
                  ),
                  _ProfileHistory(store: _store, learning: true),
                  _ProfileHistory(
                    store: _store,
                    learning: false,
                    loadUsage: widget.loadUsage,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _card(List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}

class _EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> account;
  final StudentProfileStore store;
  const _EditProfileScreen({required this.account, required this.store});
  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  late final _name = TextEditingController(
    text: widget.account['name'] as String,
  );
  late DateTime? _birthday = validBirthDate(widget.account['date_of_birth']);
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter a display name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.store.saveDetails(
        _name.text.trim(),
        _birthday?.toIso8601String().substring(0, 10),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save your profile. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit profile')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(
          controller: _name,
          enabled: !_saving,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        const SizedBox(height: 20),
        const Text(
          'Date of birth (optional)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Text(
          'You can leave this blank. Your date of birth is not shown to other students.',
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _saving
              ? null
              : () async {
                  final now = DateTime.now();
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: _birthday ?? DateTime(now.year - 15, 1, 1),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(now.year, now.month, now.day),
                    helpText: 'Date of birth (optional)',
                  );
                  if (selected != null && mounted) {
                    setState(() => _birthday = selected);
                  }
                },
          icon: const Icon(Icons.cake_outlined),
          label: Text(
            _birthday == null
                ? 'Choose date of birth'
                : '${_birthday!.day} ${_months[_birthday!.month - 1]} ${_birthday!.year}',
          ),
        ),
        if (_birthday != null)
          TextButton(
            onPressed: _saving ? null : () => setState(() => _birthday = null),
            child: const Text('Remove date of birth'),
          ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save profile'),
        ),
      ],
    ),
  );
}

class _ProfileHistory extends StatefulWidget {
  final StudentProfileStore store;
  final bool learning;
  final Future<Map<String, dynamic>> Function()? loadUsage;
  const _ProfileHistory({
    required this.store,
    required this.learning,
    this.loadUsage,
  });
  @override
  State<_ProfileHistory> createState() => _ProfileHistoryState();
}

class _ProfileHistoryState extends State<_ProfileHistory>
    with AutomaticKeepAliveClientMixin {
  final List<Map<String, dynamic>> _items = [];
  bool _loading = false, _more = true;
  String? _error;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = widget.learning
          ? null
          : await widget.store.credits(_items.length);
      final items = widget.learning
          ? await widget.store.learning(_items.length)
          : List<Map<String, dynamic>>.from(
              (result!['items'] as List).map(
                (v) => Map<String, dynamic>.from(v as Map),
              ),
            );
      if (mounted) {
        setState(() {
          _items.addAll(items);
          _more = widget.learning
              ? items.length == 20
              : result!['has_more'] == true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not load this history. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _statementColumns(
    String date,
    String description,
    String amount, {
    bool header = false,
  }) => DefaultTextStyle.merge(
    style: TextStyle(
      fontSize: 13,
      fontWeight: header ? FontWeight.w700 : FontWeight.normal,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 88, child: Text(date)),
        const SizedBox(width: 12),
        Expanded(child: Text(description)),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            amount,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _statementRow(
    String date,
    String description,
    String amount, {
    bool header = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: const BoxDecoration(
      color: Color(0xFFF1F5F9),
      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
    ),
    child: _statementColumns(date, description, amount, header: header),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (!widget.learning) ...[
          UsageMeter(loadUsage: widget.loadUsage, showRemainingTotal: true),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Credit usage statement · Dates in IST',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 16),
          _statementRow(
            'Date (IST)',
            'Description',
            'Credit (+/−)',
            header: true,
          ),
        ],
        if (widget.learning)
          const Text(
            'Your recent chats',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        if (_items.isEmpty && !_loading && _error == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              widget.learning
                  ? 'No learning sessions yet. Start learning from Home.'
                  : 'No credit usage recorded yet. New records appear after an answer is completed.',
            ),
          ),
        ..._items.map((item) {
          final raw = DateTime.tryParse(item['created_at']?.toString() ?? '');
          final date = raw?.toUtc().add(const Duration(hours: 5, minutes: 30));
          final label = date == null
              ? 'Date unavailable'
              : '${date.day}/${date.month}/${date.year} · IST';
          final creditDate = date == null
              ? 'Date unavailable'
              : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
          final credits = (item['credits_used'] as num?)?.abs().toInt() ?? 0;
          final creditAmount = credits.toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]},',
          );
          if (!widget.learning) {
            return Semantics(
              label: '$creditDate: −$creditAmount credits',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: _statementColumns(
                  creditDate,
                  item['kind']?.toString() ?? 'Tutor request',
                  '−$creditAmount',
                ),
              ),
            );
          }
          return Card(
            child: ListTile(
              leading: Icon(
                widget.learning
                    ? Icons.history_edu_outlined
                    : Icons.toll_outlined,
              ),
              title: Text(
                widget.learning
                    ? item['title']?.toString() ?? 'Study session'
                    : '$creditDate: −$creditAmount credits',
              ),
              subtitle: Text(
                widget.learning
                    ? '${boardNames[item['board']] ?? 'Board'} · Class ${item['grade_level'] ?? '—'} · ${item['subject'] ?? 'Subject'}\n$label'
                    : '${item['kind']} · IST',
              ),
              trailing: widget.learning
                  ? const Icon(Icons.chevron_right)
                  : null,
              onTap: widget.learning
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(initialSessionId: item['id'] as String),
                      ),
                    )
                  : null,
            ),
          );
        }),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_error != null) ...[
          Text(_error!),
          TextButton(onPressed: _load, child: const Text('Retry history')),
        ],
        if (_more && !_loading && _error == null)
          OutlinedButton(
            onPressed: _load,
            child: const Text('Load older records'),
          ),
      ],
    );
  }
}
