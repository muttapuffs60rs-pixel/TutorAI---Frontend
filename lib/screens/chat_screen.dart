import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; // INTEGRATED: Crop functionality core engine
import '../main.dart';
import '../widgets/custom_drawer.dart';
import 'subscription_screen.dart';

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
  const ChatScreen({super.key});

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
  String _selectedSubject = 'Science';
  final List<int> _grades = [10];
  final List<String> _subjects = ['Science', 'Maths', 'Social', 'English'];
  int _questionsAsked = 0;
  String _subscriptionTier = 'free';
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    messages = [
      ChatMessage(text: "Vanakkam! Iniku enna padikalam? 😊", isUser: false),
    ];
    _loadProfileData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialChat());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- ENHANCEMENT: FULLSCREEN VIEW ---
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
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
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

  // UPDATED WORKFLOW: Native UI crop settings refactored safely to comply with modern v8.x.x standards
  Future<File?> _cropImage(File imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Your Question',
          toolbarColor: const Color(0xFF5A189A), // Beautifully synced with darkPurple
          toolbarWidgetColor: Colors.white,
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
    return croppedFile != null ? File(croppedFile.path) : null;
  }

  // FIXED: Fully processes camera/gallery selections through the cropping channel before uploading 
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
      // Open layout cropper view before uploading raw textbook image bytes 
      final File? croppedFile = await _cropImage(File(pickedFile.path));
      if (croppedFile == null) return; // User canceled crop action

      // Upload cleanly sliced file object directly into Supabase 
      final imageUrl = await _uploadImageToSupabase(XFile(croppedFile.path));
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

  Future<String?> _uploadImageToSupabase(XFile file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final path = 'chat_uploads/$fileName';
      final Uint8List bytes = await file.readAsBytes();
      await supabase.storage.from('chat-images').uploadBinary(path, bytes);
      
      return supabase.storage.from('chat-images').getPublicUrl(path);
    } catch (e) {
      debugPrint("Image upload failed: $e");
      return null;
    }
  }

  int _getMaxQuestions() {
    if (_subscriptionTier == 'tier_49') return 50;
    if (_subscriptionTier == 'tier_99') return 100;
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

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final String originalText = _controller.text;
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

      List<String> history = messages
          .map((m) => "${m.isUser ? 'You' : 'Preethi'}: ${m.text.isNotEmpty ? m.text : '[Image]'}")
          .toList();
      if (history.length > 5) {
        history = history.sublist(history.length - 5);
      }

      final response = await http.post(
        Uri.parse('https://akka-tutor-backend.onrender.com/ask'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.id,
          'question': msg.isEmpty ? "Explain this image." : msg,
          'image_url': finalImageUrl,
          'grade_level': _selectedGrade,
          'subject': _selectedSubject,
          'is_first_message': messages.length <= 2,
          'history': history,
        }),
      ).timeout(const Duration(seconds: 60));
      // FIXED: Incremented timeout ceiling window to 60s to completely stop frontend dropping lines 

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String answer = data['answer'] ?? "No response";

        if (data['show_paywall'] ?? false) {
          answer += " [PAYWALL]";
        }

        if (!mounted) return;
        setState(() {
          messages.add(ChatMessage(text: answer, isUser: false));
        });
        await _saveMessage(answer, false);
        await _loadProfileData();
      } else {
        throw Exception('API Error');
      }
    } catch (e) {
      debugPrint("Send message error: $e");
      _controller.text = originalText;
      if (!mounted) return;
      setState(() {
        messages.add(ChatMessage(text: 'Connection Error! Please try again.', isUser: false));
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
      if (data.isNotEmpty && mounted) {
        setState(() {
          _questionsAsked = data[0]['questions_today'] ?? 0;
          _subscriptionTier = data[0]['subscription_tier'] ?? 'free';
          _selectedGrade = data[0]['grade_level'] ?? 10;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    int maxLimit = _getMaxQuestions();
    int questionsLeft = (maxLimit - _questionsAsked).clamp(0, maxLimit);
    const Color themePurple = Color(0xFF7B2CBF);
    const Color darkPurple = Color(0xFF5A189A);
    return Scaffold(
      backgroundColor: themePurple,
      appBar: AppBar(
        backgroundColor: darkPurple,
        title: const Text('Tutor Preethi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.add_comment, color: Colors.white), onPressed: _startNewChat),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutConfirmation,
          )
        ],
      ),
      drawer: CustomDrawer(
        key: UniqueKey(),
        questionsLeft: questionsLeft,
        maxLimit: maxLimit,
        subscriptionTier: _subscriptionTier,
        onSessionSelected: (sessionId) {
          Navigator.pop(context);
          _loadChatHistory(sessionId);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: darkPurple.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDropdown<int>(_selectedGrade, _grades, (val) {
                    if (val != null) setState(() => _selectedGrade = val);
                  }, Icons.school, "Class"),
                  _buildDropdown<String>(_selectedSubject, _subjects, (val) {
                    if (val != null) {
                      setState(() => _selectedSubject = val);
                      _startNewChat();
                    }
                  }, Icons.menu_book, ""),
                ],
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
            _buildInputArea(darkPurple),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(T value, List<T> items, ValueChanged<T?> onChanged, IconData icon, String prefix) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 8),
        DropdownButton<T>(
          value: value,
          dropdownColor: const Color(0xFF5A189A),
          underline: const SizedBox(),
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          onChanged: items.length > 1 ? onChanged : null,
          items: items.map((T item) => DropdownMenuItem<T>(value: item, child: Text('$prefix $item'))).toList(),
        ),
      ],
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
                borderRadius: BorderRadius.circular(12),
                child: Image.network(message.imageUrl!, fit: BoxFit.cover),
              ),
            ),
          ),
        if (displayText.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: message.isUser ? const Color(0xFF9D4EDD) : const Color(0xFF3C096C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: MarkdownBody(
              data: displayText,
              styleSheet: MarkdownStyleSheet( 
                p: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
                h1: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold),
                strong: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                listBullet: const TextStyle(color: Colors.white, fontSize: 18),
                code: const TextStyle(backgroundColor: Color(0xFF1E1E1E), color: Color(0xFF00FFCC), fontFamily: 'monospace', fontSize: 14),
                blockquoteDecoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(left: BorderSide(color: Colors.amber, width: 4)),
                ),
                blockquote: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        if (isPaywall)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
              icon: const Icon(Icons.star, color: Colors.amber, size: 18),
              label: const Text('Upgrade to Preethi Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            ),
          )
        else
          const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildInputArea(Color fillColor) {
    return Column(
      children: [
        if (_pendingImageUrl != null)
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
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: NetworkImage(_pendingImageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _pendingImageUrl = null),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(width: 12),
                const Text("Image ready to send", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(color: fillColor, borderRadius: BorderRadius.circular(30)),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_a_photo, color: Colors.white70), 
                  onPressed: isLoading ? null : _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !isLoading,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Ask Preethi a question...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.white70),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (val) => sendMessage(text: val),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: isLoading 
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () => sendMessage(), 
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}