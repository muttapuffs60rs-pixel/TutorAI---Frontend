import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/board_selection_screen.dart';
import '../screens/home_selection_screen.dart';
import '../screens/student_tutorial.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/login_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/student_profile_screen.dart';
import '../theme/tailwind_theme.dart';
import '../screens/chat_screen.dart';
import '../services/profile_service.dart';
import '../screens/answer_library_screen.dart';
import 'usage_meter.dart';
import '../screens/legal_policy_screen.dart';
import '../screens/Support_screen.dart';

class CustomDrawer extends StatefulWidget {
  final Future<Map<String, dynamic>> Function()? loadUsage;
  final String? subscriptionTier;
  final String? subscriptionStartDate;
  final String? subscriptionExpiresAt;
  final Function(String)? onSessionSelected;
  final Function(String)? onSessionDeleted;

  const CustomDrawer({
    super.key,
    this.loadUsage,
    this.subscriptionTier,
    this.subscriptionStartDate,
    this.subscriptionExpiresAt,
    this.onSessionSelected,
    this.onSessionDeleted,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoadingSessions = true;
  bool _isLoadingProfile = true;

  String _subscriptionTier = 'free';
  String? _subscriptionExpiresAt;

  @override
  void initState() {
    super.initState();
    _fetchChatSessions();
    if (widget.subscriptionTier != null) {
      _subscriptionTier = widget.subscriptionTier ?? 'free';
      _subscriptionExpiresAt = widget.subscriptionExpiresAt;
      _isLoadingProfile = false;
    } else {
      _fetchProfileData();
    }
  }

  Future<void> _fetchProfileData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _isLoadingSessions = false;
        });
      }
      return;
    }
    try {
      final profile = await fetchDailyProfile();
      String subTier = profile['subscription_tier'] ?? 'free';
      if (mounted) {
        setState(() {
          _subscriptionTier = subTier;
          _subscriptionExpiresAt = profile['subscription_expires_at'];
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile data: $e");
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _fetchChatSessions() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _isLoadingSessions = false;
        });
      }
      return;
    }

    try {
      // FIX: Changed table name from 'chats' to 'chat_sessions' to ensure continuity
      final data = await supabase
          .from('chat_sessions')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _sessions = List<Map<String, dynamic>>.from(data);
          _isLoadingSessions = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      if (mounted) setState(() => _isLoadingSessions = false);
    }
  }

  void _confirmDeleteSession(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Tailwind.white,
          shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl),
          title: const Text(
            "Delete Chat",
            style: TextStyle(
              color: Tailwind.slate800,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Are you sure you want to delete this chat history? This cannot be undone.",
            style: TextStyle(color: Tailwind.slate600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Tailwind.slate500),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteSession(sessionId);
              },
              child: const Text(
                "Delete",
                style: TextStyle(
                  color: Tailwind.rose500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSession(String sessionId) async {
    try {
      await supabase.from('chat_messages').delete().eq('session_id', sessionId);
      await supabase.from('chat_sessions').delete().eq('id', sessionId);
      _fetchChatSessions();
      if (widget.onSessionDeleted != null) {
        widget.onSessionDeleted!(sessionId);
      }
    } catch (e) {
      debugPrint("Error deleting session: $e");
    }
  }

  Future<void> _open(Widget screen) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await navigator.push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted &&
        (screen is SubscriptionScreen || screen is StudentProfileScreen)) {
      _fetchProfileData();
    }
  }

  String get _planName =>
      const {
        'free': 'Free',
        'tier_199': 'Standard',
        'tier_499': 'Syllabus Master',
        'tier_999': 'Premium',
        'admin': 'Admin',
      }[_subscriptionTier] ??
      'Learning';

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
    child: Text(
      label,
      style: const TextStyle(
        color: Tailwind.slate500,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 1,
      ),
    ),
  );

  void _logout() {
    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign in again to continue learning.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await supabase.auth.signOut();
              if (navigator.mounted) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final String name =
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['username'] ??
        'Student';
    final width = (MediaQuery.sizeOf(context).width - 24).clamp(0.0, 360.0);
    return Drawer(
      width: width,
      backgroundColor: const Color(0xfff7f8fa),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your learning space',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Tailwind.slate800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close menu',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Tailwind.slate600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Tailwind.indigo100,
                          child: Text(
                            name.isEmpty ? 'S' : name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Tailwind.indigo600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Tailwind.slate800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                user?.email ?? 'Student account',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Tailwind.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Tailwind.slate800,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR PLAN',
                          style: TextStyle(
                            color: Color(0xffbdcbd1),
                            fontSize: 11,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLoadingProfile
                              ? 'Loading plan…'
                              : '$_planName plan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_subscriptionExpiresAt != null &&
                            _subscriptionTier != 'free') ...[
                          const SizedBox(height: 6),
                          Text(
                            'Valid until ${_formatDate(_subscriptionExpiresAt)}',
                            style: const TextStyle(
                              color: Color(0xffd8e2e6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => _open(const SubscriptionScreen()),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Tailwind.slate800,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'View plans',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  UsageMeter(loadUsage: widget.loadUsage),
                  _section('LEARN'),
                  _menuAction(
                    leading: const Icon(Icons.school_outlined),
                    title: const Text('Board & curriculum'),
                    subtitle: Text(
                      boardNames[savedBoard(user?.userMetadata)] ??
                          'Select your board',
                    ),
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => BoardSelectionScreen(
                            changing: true,
                            initialBoard: savedBoard(user?.userMetadata),
                            onSave: (board) async {
                              await supabase.auth.updateUser(
                                UserAttributes(
                                  data: {'education_board': board},
                                ),
                              );
                              if (!navigator.mounted) return;
                              navigator.pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const HomeSelectionScreen(),
                                ),
                                (_) => false,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  _menuAction(
                    leading: const Icon(Icons.groups_outlined),
                    title: const Text('Quizzes'),
                    subtitle: const Text('Practise alone, join or host'),
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.pushNamed('/live-quiz');
                    },
                  ),
                  _section('RECENT CHATS'),
                  if (_isLoadingSessions)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: LinearProgressIndicator(),
                    )
                  else if (_sessions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Text(
                        'Your saved conversations will appear here.',
                        style: TextStyle(
                          color: Tailwind.slate500,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    ..._sessions.map(
                      (session) => _menuAction(
                        leading: const Icon(
                          Icons.chat_bubble_outline,
                          size: 20,
                        ),
                        title: Text(
                          session['title'] ?? 'New chat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: 'Delete chat',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Tailwind.rose500,
                            size: 20,
                          ),
                          onPressed: () =>
                              _confirmDeleteSession(context, session['id']),
                        ),
                        onTap: () {
                          if (widget.onSessionSelected != null) {
                            widget.onSessionSelected!(session['id']);
                          } else {
                            _open(ChatScreen(initialSessionId: session['id']));
                          }
                        },
                      ),
                    ),
                  _section('HELP & ACCOUNT'),
                  _menuAction(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: const Text('My profile'),
                    subtitle: const Text(
                      'Account, learning and credit history',
                    ),
                    onTap: () => _open(const StudentProfileScreen()),
                  ),
                  _menuAction(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('How to use Arivora'),
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      StudentTutorial.show(navigator.context);
                    },
                  ),
                  _menuAction(
                    leading: const Icon(Icons.mail_outline),
                    title: const Text('Contact support'),
                    subtitle: const Text('arivora_support@auxiumsoft.com'),
                    onTap: () => _open(const SupportScreen()),
                  ),
                  _menuAction(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change password'),
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.pushNamed('/change-password');
                    },
                  ),
                  if (_subscriptionTier == 'admin')
                    _menuAction(
                      leading: const Icon(Icons.fact_check_outlined),
                      title: const Text('Answer library'),
                      onTap: () => _open(const AnswerLibraryScreen()),
                    ),
                  _section('POLICIES'),
                  _menuAction(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Terms & conditions'),
                    onTap: () => _open(
                      const LegalPolicyScreen(policy: LegalPolicy.terms),
                    ),
                  ),
                  _menuAction(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Cancellation & refunds'),
                    onTap: () => _open(
                      const LegalPolicyScreen(policy: LegalPolicy.refunds),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _menuAction(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: Tailwind.rose500,
                    ),
                    title: const Text(
                      'Sign out',
                      style: TextStyle(color: Tailwind.rose600),
                    ),
                    onTap: _logout,
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Text(
                      'Arivora · An AuxiumSoft product',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Tailwind.slate500, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuAction({
    required Widget leading,
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Tailwind.slate200),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          hoverColor: Tailwind.indigo100,
          focusColor: Tailwind.indigo100,
          splashColor: Tailwind.indigo100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Tailwind.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: leading),
          ),
          title: title,
          subtitle: subtitle,
          titleTextStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Tailwind.slate800,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          subtitleTextStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Tailwind.slate500,
            fontSize: 12,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?trailing,
              const Icon(
                Icons.chevron_right_rounded,
                color: Tailwind.indigo600,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(
        isoString,
      ).toUtc().add(const Duration(hours: 5, minutes: 30));
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (e) {
      return isoString;
    }
  }
}
