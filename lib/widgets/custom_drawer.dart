import 'package:flutter/material.dart';
import '../main.dart'; 
import '../screens/login_screen.dart';
import '../screens/subscription_screen.dart';

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
      backgroundColor: const Color(0xFF2E0249), 
      child: Column( 
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFF5A189A)), 
                  accountName: Text(
                    displayName, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
                  ),
                  accountEmail: Text(
                    user?.email ?? 'Unknown User',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S', 
                      style: const TextStyle(fontSize: 24, color: Color(0xFF7B2CBF), fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
                
                ListTile(
                  leading: Icon(
                    Icons.bolt, 
                    color: widget.questionsLeft > 0 ? Colors.amber : Colors.redAccent
                  ),
                  title: Text(
                    '${widget.questionsLeft} / ${widget.maxLimit} Questions Left',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Current Plan: ${widget.subscriptionTier.toUpperCase()}',
                    style: const TextStyle(color: Colors.white60),
                  ),
                ),
                
                const Divider(color: Colors.white24),

                ListTile(
                  leading: const Icon(Icons.upgrade, color: Colors.greenAccent),
                  title: const Text('Upgrade Plan', style: TextStyle(color: Colors.white)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'OFFER',
                      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
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
                leading: const Icon(Icons.lock_reset, color: Colors.white),
                title: const Text('Change Password', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.pushNamed(context, '/change-password'); // Push screen
                  },
                ),

                const Divider(color: Colors.white24),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    "RECENT CHATS",
                    style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),

                if (_isLoadingSessions)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(color: Colors.white54),
                  ))
                else if (_sessions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("No history yet.", style: TextStyle(color: Colors.white38, fontSize: 14)),
                  )
                else
                  ..._sessions.map((session) => ListTile(
                    leading: const Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 20),
                    title: Text(
                      session['title'] ?? 'New Chat',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
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

          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text('Log Out', style: TextStyle(color: Colors.white70)),
            onTap: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()), 
                  (route) => false
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}