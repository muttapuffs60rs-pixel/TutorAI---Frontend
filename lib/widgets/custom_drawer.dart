import 'package:flutter/material.dart';
import '../main.dart'; 
import '../screens/login_screen.dart';
import '../screens/subscription_screen.dart';
import '../theme/tailwind_theme.dart';

class CustomDrawer extends StatefulWidget {
  final int questionsLeft;
  final int maxLimit;
  final String subscriptionTier;
  final Function(String) onSessionSelected; 

  const CustomDrawer({
    super.key,
    required this.questionsLeft,
    required this.maxLimit,
    required this.subscriptionTier,
    required this.onSessionSelected,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoadingSessions = true;

  @override
  void initState() {
    super.initState();
    _fetchChatSessions();
  }

  Future<void> _fetchChatSessions() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

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

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final String displayName = user?.userMetadata?['full_name'] ?? 
                               user?.userMetadata?['username'] ?? 'Student';

    return Drawer(
      backgroundColor: Tailwind.white, 
      child: Column( 
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Tailwind.indigo600), 
                  accountName: Text(
                    displayName, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Tailwind.white)
                  ),
                  accountEmail: Text(
                    user?.email ?? 'Unknown User',
                    style: const TextStyle(color: Tailwind.indigo100),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Tailwind.white,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S', 
                      style: const TextStyle(fontSize: 24, color: Tailwind.indigo600, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
                
                ListTile(
                  leading: Icon(
                    Icons.bolt, 
                    color: widget.questionsLeft > 0 ? Tailwind.amber500 : Tailwind.rose500
                  ),
                  title: Text(
                    '${widget.questionsLeft} / ${widget.maxLimit} Questions Left',
                    style: const TextStyle(color: Tailwind.slate800, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Current Plan: ${widget.subscriptionTier.toUpperCase()}',
                    style: const TextStyle(color: Tailwind.slate500, fontWeight: FontWeight.w500),
                  ),
                ),
                
                const Divider(color: Tailwind.slate200),

                ListTile(
                  leading: const Icon(Icons.upgrade, color: Tailwind.emerald500),
                  title: const Text('Upgrade Plan', style: TextStyle(color: Tailwind.slate800, fontWeight: FontWeight.w600)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Tailwind.amber500,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'OFFER',
                      style: TextStyle(color: Tailwind.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                    );
                  },
                ),

                ListTile(
                leading: const Icon(Icons.lock_reset, color: Tailwind.slate500),
                title: const Text('Change Password', style: TextStyle(color: Tailwind.slate800, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.pushNamed(context, '/change-password'); // Push screen
                  },
                ),

                const Divider(color: Tailwind.slate200),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    "RECENT CHATS",
                    style: TextStyle(color: Tailwind.slate400, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),

                if (_isLoadingSessions)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(color: Tailwind.indigo500),
                  ))
                else if (_sessions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("No history yet.", style: TextStyle(color: Tailwind.slate400, fontSize: 14)),
                  )
                else
                  ..._sessions.map((session) => ListTile(
                    leading: const Icon(Icons.chat_bubble_outline, color: Tailwind.slate400, size: 20),
                    title: Text(
                      session['title'] ?? 'New Chat',
                      style: const TextStyle(color: Tailwind.slate700, fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      widget.onSessionSelected(session['id']); 
                      // Removed Navigator.pop here because it is handled in ChatScreen's callback
                    },
                  )),
              ],
            ),
          ),

          const Divider(color: Tailwind.slate200),
          ListTile(
            leading: const Icon(Icons.logout, color: Tailwind.rose500),
            title: const Text('Log Out', style: TextStyle(color: Tailwind.rose500, fontWeight: FontWeight.w600)),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Tailwind.white,
                    shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl),
                    title: const Text("Logout", style: TextStyle(color: Tailwind.slate800)),
                    content: const Text("Are you sure you want to log out?", style: TextStyle(color: Tailwind.slate600)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel", style: TextStyle(color: Tailwind.slate500)),
                      ),
                      TextButton(
                        onPressed: () async {
                          await supabase.auth.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()), 
                              (route) => false
                            );
                          }
                        },
                        child: const Text("Logout", style: TextStyle(color: Tailwind.rose500, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}