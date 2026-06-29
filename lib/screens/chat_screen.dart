import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
// INTEGRATED: Crop functionality core engine
import '../main.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/subject_picker_sheet.dart';
import 'subscription_screen.dart';
import '../theme/tailwind_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? imageUrl;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imageUrl,
  });
}

class ChatScreen extends StatefulWidget {
  final String? initialSubject;
  final int? initialGradeLevel;
  final String? initialSessionId;
  const ChatScreen({super.key, this.initialSubject, this.initialGradeLevel, this.initialSessionId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<ChatMessage> messages = [];
  bool isLoading = false;
  String? _pendingImageUrl; 
  
  int _selectedGrade = 10;
  late String _selectedSubject;
  int _questionsAsked = 0;
  String _subscriptionTier = 'free';
  String? _subscriptionStartDate;
  String? _subscriptionExpiresAt;
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _selectedGrade = widget.initialGradeLevel ?? 10;
    _selectedSubject = widget.initialSubject ?? 'Science'; 

    messages = [
      ChatMessage(text: "Vanakkam! Iniku enna padikalam? 😊", isUser: false),
    ];

    if (widget.initialSessionId != null) {
      // Defer loading until after initial build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadChatHistory(widget.initialSessionId!);
      });
    }

    _loadProfileData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialChat());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showFullScreenImage(String url) {
    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black,
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await supabase.auth.signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadInitialChat() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // ADDED: If the user explicitly picked a subject from the home screen, start a fresh chat automatically!
    if (widget.initialSubject != null) {
      await _startNewChat();
      return;
    }

    try {
      final sessionData = await supabase
          .from('chat_sessions')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1);
      if (sessionData.isNotEmpty) {
        await _loadChatHistory(sessionData[0]['id']);
      } else {
        await _startNewChat();
      }
    } catch (e) {
      debugPrint("Error loading initial chat: $e");
    }
  }

  Future<void> _startNewChat() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final newSession = await supabase.from('chat_sessions').insert({
        'user_id': user.id,
        'title': 'New Chat',
      }).select();
      if (!mounted) return;
      setState(() {
        _currentSessionId = newSession[0]['id'];
        messages = [
          ChatMessage(text: "Vanakkam! Iniku enna padikalam? 😊", isUser: false),
        ];
      });
    } catch (e) {
      debugPrint("Error creating new session: $e");
    }
  }

  Future<void> _loadChatHistory(String sessionId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('chat_messages')
          .select()
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);
      if (!mounted) return;
      setState(() {
        _currentSessionId = sessionId;
        messages = List<ChatMessage>.from(
          (data as List).map((row) => ChatMessage(
            text: row['message'] ?? '',
            isUser: row['is_user'] ?? false,
            imageUrl: row['image_url'],
          )),
        );

        if (messages.isEmpty) {
          messages = [
            ChatMessage(text: "Vanakkam! Iniku enna padikalam? 😊", isUser: false),
          ];
        }
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error loading history: $e");
    }
  }

  Future<void> _saveMessage(String text, bool isUser) async {
    final user = supabase.auth.currentUser;
    if (user == null || _currentSessionId == null) return;

    try {
      await supabase.from('chat_messages').insert({
        'user_id': user.id,
        'session_id': _currentSessionId,
        'message': text,
        'is_user': isUser,
      });
      final session = await supabase
          .from('chat_sessions')
          .select('title')
          .eq('id', _currentSessionId!)
          .single();
      if (isUser && session['title'] == 'New Chat') {
        String shortTitle = text.length > 25 ?
        "${text.substring(0, 25)}..." : text;
        await supabase.from('chat_sessions').update({'title': shortTitle}).eq('id', _currentSessionId!);
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Error saving message: $e");
    }
  }

  Future<void> _saveMessageWithImage(String text, bool isUser, String imageUrl) async {
    final user = supabase.auth.currentUser;
    if (user == null || _currentSessionId == null) return;

    try {
      await supabase.from('chat_messages').insert({
        'user_id': user.id,
        'session_id': _currentSessionId,
        'message': text,
        'is_user': isUser,
        'image_url': imageUrl,
      });
    } catch (e) {
      debugPrint("Error saving image message: $e");
    }
  }

  Future<CroppedFile?> _cropImage(XFile imageFile) async {
    return await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Your Question',
          toolbarColor: Tailwind.indigo600, 
          toolbarWidgetColor: Tailwind.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
          ],
        ),
        IOSUiSettings(
          title: 'Crop Your Question',
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
          ],
        ),
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
          size: const CropperSize(width: 400, height: 400),
        ),
      ],
   );
  }

  Future<void> _pickImage() async {
    if (isLoading) return;
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1200,
    );
    if (pickedFile == null) return;

    try {
      if (mounted) setState(() => isLoading = true);
      final CroppedFile? croppedFile = await _cropImage(pickedFile);
      if (croppedFile == null) return; 

      final Uint8List bytes = await croppedFile.readAsBytes();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';

      final imageUrl = await _uploadImageToSupabase(fileName, bytes);
      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception("Upload failed");
      }

      if (mounted) {
        setState(() {
          _pendingImageUrl = imageUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload image")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<String?> _uploadImageToSupabase(String fileName, Uint8List bytes) async {
    try {
      final path = 'chat_uploads/$fileName';
      await supabase.storage.from('chat-images').uploadBinary(path, bytes);
      
      return supabase.storage.from('chat-images').getPublicUrl(path);
    } catch (e) {
      debugPrint("Image upload failed: $e");
      return null;
    }
  }

  int _getMaxQuestions() {
    if (_subscriptionTier == 'tier_199') return 50;
    if (_subscriptionTier == 'tier_499') return 150;
    if (_subscriptionTier == 'tier_49' || _subscriptionTier == 'tier_49_daily' || _subscriptionTier == 'admin') return 999999;
    return 5;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- ENHANCEMENT: ERROR-HANDLING + VISION ---
  Future<void> sendMessage({String? text, String? imageUrl}) async {
    final finalImageUrl = imageUrl ?? _pendingImageUrl;
    final msg = text?.trim() ?? _controller.text.trim();

    if ((msg.isEmpty && (finalImageUrl == null || finalImageUrl.isEmpty)) || isLoading) {
      return;
    }

    // Evaluate tier constraints dynamically
    if (_subscriptionTier != 'admin' && _subscriptionTier != 'tier_49' && _subscriptionTier != 'tier_49_daily' && _questionsAsked >= _getMaxQuestions()) {
      setState(() {
        messages.add(ChatMessage(text: "Your limit per day is over. Upgrade plan to ask more questions!", isUser: false));
      });
      return;
    }

    final int userQuestionsCount = messages.where((m) => m.isUser).length;
    if (_subscriptionTier != 'admin' && userQuestionsCount >= 20) {
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final String originalText = _controller.text;

    // Build lightweight history map BEFORE appending the new user message to prevent loop duplication
    final recentMessages = messages.length > 12 ? messages.sublist(messages.length - 12) : messages;
    final List<Map<String, String>> historyPayload = recentMessages.map((m) {
      return {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text.isNotEmpty ? m.text : '[Image attachment]'
      };
    }).toList();

    // Now safely add the current message to the UI
    setState(() {
      messages.add(ChatMessage(text: msg, isUser: true, imageUrl: finalImageUrl));
      _controller.clear();
      _pendingImageUrl = null; 
      isLoading = true; 
    });
    _scrollToBottom();

    try {
      if (finalImageUrl != null && finalImageUrl.isNotEmpty) {
        await _saveMessageWithImage(msg, true, finalImageUrl);
      } else {
        await _saveMessage(msg, true);
      }

      // Create a placeholder bot message for the incoming stream
      final botMessageIndex = messages.length;
      setState(() {
        messages.add(ChatMessage(text: "Tutor is thinking...", isUser: false));
      });

      final session = supabase.auth.currentSession;
      final String token = session?.accessToken ?? '';

      final request = http.Request('POST', Uri.parse('https://akka-tutor-backend.onrender.com/ask'));
      request.headers['Content-Type'] = 'application/json';
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.body = jsonEncode({
        'question': msg.isEmpty ? "Explain this image." : msg,
        'image_url': finalImageUrl,
        'grade_level': _selectedGrade,
        'subject': _selectedSubject,
        'history': historyPayload, 
      });

      final client = http.Client();
      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 60));

      if (streamedResponse.statusCode == 200) {
        String fullAnswer = "";
        bool showPaywall = false;

        // Listen to the byte stream in real-time
        await for (var chunkBytes in streamedResponse.stream) {
          final chunkString = utf8.decode(chunkBytes, allowMalformed: true);
          
          if (chunkString.contains("__PAYWALL__")) {
             showPaywall = true;
             fullAnswer += chunkString.replaceAll("__PAYWALL__", "");
          } else {
             fullAnswer += chunkString;
          }

          if (!mounted) return;
          setState(() {
            // Update the existing message in real-time for the "typing" effect
            messages[botMessageIndex] = ChatMessage(text: fullAnswer + (showPaywall ? " [PAYWALL]" : ""), isUser: false);
          });
          _scrollToBottom();
        }

        // Save the final completed message
        await _saveMessage(fullAnswer + (showPaywall ? " [PAYWALL]" : ""), false);
        await _loadProfileData();

        if (messages.where((m) => m.isUser).length >= 20) {
          FocusScope.of(context).unfocus();
        }
      } else {
        throw Exception('API Error');
      }
    } catch (e) {
      debugPrint("Send message error: $e");
      _controller.text = originalText;
      if (!mounted) return;
      setState(() {
        if (messages.isNotEmpty && messages.last.text == "Tutor is thinking...") {
          messages[messages.length - 1] = ChatMessage(text: 'Connection Error! Please try again.', isUser: false);
        } else {
          messages.add(ChatMessage(text: 'Connection Error! Please try again.', isUser: false));
        }
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _loadProfileData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await supabase.from('profiles').select().eq('id', user.id);
      if (data.isNotEmpty) {
        final profile = data[0];
        
        int chatsToday = profile['chats_today'] ?? 0;
        String subTier = profile['subscription_tier'] ?? 'free';
        String? prevTier = profile['previous_tier'];
        String? lastActive = profile['last_active_date'];

        // Get local date string 'YYYY-MM-DD'
        final todayStr = DateTime.now().toIso8601String().split('T')[0];

        bool needsUpdate = false;
        
        // LAZY RESET LOGIC
        if (lastActive != todayStr) {
          chatsToday = 0;
          // Revert Exam Booster access on the next day
          if (subTier == 'tier_49_daily') {
            subTier = prevTier ?? 'free';
            prevTier = null;
          }
          needsUpdate = true;
        }

        if (needsUpdate) {
          try {
            await supabase.from('profiles').update({
              'chats_today': chatsToday,
              'subscription_tier': subTier,
              'previous_tier': prevTier,
              'last_active_date': todayStr,
            }).eq('id', user.id);
          } catch (e) {
            debugPrint("Failed to update daily reset columns. Did you add previous_tier and last_active_date to Supabase? $e");
          }
        }

        if (mounted) {
          setState(() {
            _questionsAsked = chatsToday;
            _subscriptionTier = subTier;
            _subscriptionStartDate = profile['subscription_start_date'];
            _subscriptionExpiresAt = profile['subscription_expires_at'];
            // Only update grade if it's the very first load or somehow missing
            if (_selectedGrade == 10 && profile['grade_level'] != null) {
              _selectedGrade = profile['grade_level'];
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    int maxLimit = _getMaxQuestions();
    int questionsLeft = _subscriptionTier == 'tier_49' || _subscriptionTier == 'tier_49_daily' || _subscriptionTier == 'admin' 
        ? 9999 
        : (maxLimit - _questionsAsked).clamp(0, maxLimit);
        
    return Scaffold(
      backgroundColor: Tailwind.slate50,
      appBar: AppBar(
        backgroundColor: Tailwind.white,
        title: const Text('Tutor Preethi', style: TextStyle(fontWeight: FontWeight.bold, color: Tailwind.slate800)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Tailwind.slate800),
        actions: [
          IconButton(icon: const Icon(Icons.add_comment, color: Tailwind.indigo600), onPressed: _startNewChat),
          IconButton(
            icon: const Icon(Icons.logout, color: Tailwind.slate500),
            onPressed: _showLogoutConfirmation,
          )
        ],
      ),
      drawer: CustomDrawer(
        key: ValueKey<int>(_questionsAsked),
        questionsLeft: questionsLeft,
        maxLimit: maxLimit,
        subscriptionTier: _subscriptionTier,
        subscriptionStartDate: _subscriptionStartDate,
        subscriptionExpiresAt: _subscriptionExpiresAt,
        onSessionSelected: (sessionId) {
          Navigator.pop(context);
          _loadChatHistory(sessionId);
        },
        onSessionDeleted: (sessionId) {
          if (_currentSessionId == sessionId) {
            Navigator.pop(context); // Close the drawer on active session deletion
            _startNewChat();
          }
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Tailwind.white,
                boxShadow: Tailwind.shadowSm,
              ),
              child: GestureDetector(
                onTap: _showSubjectPicker,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Tailwind.indigo50, shape: BoxShape.circle),
                      child: const Icon(Icons.school, size: 20, color: Tailwind.indigo600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Class $_selectedGrade', style: const TextStyle(color: Tailwind.slate500, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(_selectedSubject, style: const TextStyle(color: Tailwind.slate800, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Tailwind.slate400),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) => _buildChatBubble(messages[index]),
              ),
            ),
            _buildInputArea(Tailwind.white),
          ],
        ),
      ),
    );
  }

  void _showSubjectPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SubjectPickerSheet(
          initialGrade: _selectedGrade,
          onSubjectSelected: (grade, subject) {
            setState(() {
              _selectedGrade = grade;
              _selectedSubject = subject;
            });
            _startNewChat();
          },
        );
      },
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isPaywall = message.text.contains('[PAYWALL]');
    final displayText = message.text.replaceFirst('[PAYWALL]', '');
    return Column(
      crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (message.imageUrl != null)
          GestureDetector(
            onTap: () => _showFullScreenImage(message.imageUrl!), 
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              constraints: const BoxConstraints(maxWidth: 250),
              child: ClipRRect(
                borderRadius: Tailwind.roundedXl,
                child: Image.network(message.imageUrl!, fit: BoxFit.cover),
              ),
            ),
          ),
        if (displayText.isNotEmpty)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutExpo,
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: message.isUser ? Tailwind.indigo600 : Tailwind.white,
                borderRadius: Tailwind.rounded2Xl.copyWith(
                  bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
                  bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
                ),
                boxShadow: Tailwind.shadowSm,
                border: message.isUser ? null : Border.all(color: Tailwind.slate200),
              ),
              child: displayText == "Tutor is thinking..."
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Tailwind.indigo500),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Tutor is thinking...",
                          style: TextStyle(
                            color: Tailwind.slate500,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                  : MarkdownBody(
                      data: displayText,
                      styleSheet: MarkdownStyleSheet( 
                        p: TextStyle(color: message.isUser ? Tailwind.white : Tailwind.slate800, fontSize: 16, height: 1.5),
                        h1: TextStyle(color: message.isUser ? Tailwind.white : Tailwind.slate900, fontSize: 20, fontWeight: FontWeight.bold),
                        strong: TextStyle(fontWeight: FontWeight.bold, color: message.isUser ? Tailwind.indigo50 : Tailwind.indigo600),
                        listBullet: TextStyle(color: message.isUser ? Tailwind.white : Tailwind.slate800, fontSize: 16),
                        code: TextStyle(backgroundColor: Tailwind.slate100, color: Tailwind.rose500, fontFamily: 'monospace', fontSize: 14),
                        blockquoteDecoration: BoxDecoration(
                          color: Tailwind.slate50,
                          borderRadius: Tailwind.roundedMd,
                          border: const Border(left: BorderSide(color: Tailwind.indigo500, width: 4)),
                        ),
                        blockquote: const TextStyle(color: Tailwind.slate700, fontSize: 15, fontStyle: FontStyle.italic),
                      ),
                    ),
            ),
          ),
        if (isPaywall)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
              icon: const Icon(Icons.star, color: Tailwind.white, size: 18),
              label: const Text('Upgrade to Preethi Pro', style: TextStyle(color: Tailwind.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Tailwind.amber500,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl)
              ),
            ),
          )
        else
          const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildInputArea(Color fillColor) {
    final int userQuestionsCount = messages.where((m) => m.isUser).length;
    final bool isSessionLimitReached = _subscriptionTier != 'admin' && userQuestionsCount >= 20;
    
    final bool isSubscriptionLimitReached = _subscriptionTier != 'admin' && _subscriptionTier != 'tier_49' && _subscriptionTier != 'tier_49_daily' && _questionsAsked >= _getMaxQuestions();
    final bool blockInput = isSessionLimitReached || isSubscriptionLimitReached;

    return Column(
      children: [
        if (_pendingImageUrl != null && !blockInput)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: Tailwind.roundedXl,
                        boxShadow: Tailwind.shadowSm,
                        image: DecorationImage(
                          image: NetworkImage(_pendingImageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: GestureDetector(
                        onTap: () => setState(() => _pendingImageUrl = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Tailwind.rose500, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 14, color: Tailwind.white),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(width: 12),
                const Text("Image ready to send", style: TextStyle(color: Tailwind.slate500, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: blockInput
                ? Container(
                    key: const ValueKey("SessionLimitCTA"),
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSubscriptionLimitReached ? Tailwind.indigo600 : Tailwind.amber500,
                        foregroundColor: isSubscriptionLimitReached ? Tailwind.white : Tailwind.slate900,
                        shape: RoundedRectangleBorder(
                          borderRadius: Tailwind.roundedFull,
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSubscriptionLimitReached 
                        ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()))
                        : _startNewChat,
                      icon: Icon(isSubscriptionLimitReached ? Icons.star : Icons.refresh, fontWeight: FontWeight.bold),
                      label: Text(
                        isSubscriptionLimitReached 
                          ? "Your limit per day is over! Upgrade to Pro" 
                          : "Session Limit Reached! Start New Chat",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  )
                : Container(
                    key: const ValueKey("StandardChatField"),
                    decoration: BoxDecoration(
                      color: fillColor, 
                      borderRadius: Tailwind.roundedFull,
                      boxShadow: Tailwind.shadowSm,
                      border: Border.all(color: Tailwind.slate200),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_a_photo, color: Tailwind.indigo500), 
                          onPressed: isLoading ? null : () {
                            if (_subscriptionTier == 'free') {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Tailwind.white,
                                  shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl),
                                  title: const Text("Premium Feature", style: TextStyle(color: Tailwind.slate800, fontWeight: FontWeight.bold)),
                                  content: const Text("Upgrade to use the feature. Image analysis unlocks homework scanning and instant solutions!", style: TextStyle(color: Tailwind.slate600)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancel", style: TextStyle(color: Tailwind.slate500)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Tailwind.indigo600, foregroundColor: Tailwind.white, shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedLg)),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                                      },
                                      child: const Text("Upgrade", style: TextStyle(fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                              );
                              return;
                            }
                            _pickImage();
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            enabled: !isLoading,
                            style: const TextStyle(color: Tailwind.slate800),
                            decoration: const InputDecoration(
                              hintText: 'Ask Preethi a question...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Tailwind.slate400),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onSubmitted: (val) => sendMessage(text: val),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: isLoading 
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Tailwind.indigo600, strokeWidth: 2.5),
                                ),
                              )
                            : Container(
                                margin: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Tailwind.indigo600,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.send, color: Tailwind.white, size: 18),
                                  onPressed: () => sendMessage(), 
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}