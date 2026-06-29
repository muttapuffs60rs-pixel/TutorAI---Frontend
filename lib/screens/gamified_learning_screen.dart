import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../main.dart';
import '../theme/tailwind_theme.dart';
import '../services/game_analytics.dart';
import '../services/progress_service.dart';
import '../services/xp_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Protocol Constants  (mirrors flutterBridge.ts)
// ─────────────────────────────────────────────────────────────────────────────
const _flutterAppVersion = '1.0.0';
const _protocolVersion   = 3;          // Must match PROTOCOL_VERSION in bridge
const _readyTimeout      = Duration(seconds: 12);

// ─────────────────────────────────────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────────────────────────────────────

/// A native lesson screen hosting the React physics simulation engine.
/// Flutter owns navigation, auth, XP, and all UI chrome.
/// React renders physics only and never calls Supabase.
class GamifiedLearningScreen extends StatefulWidget {
  final String? initialGame;
  final String? lessonId;
  final String  topicTitle;
  final String  engineBaseUrl;

  // ── Service injection (item 6) ──────────────────────────────────────────
  // Pass real services from a DI layer, or leave null to use internal singletons.
  final ProgressService? progressService;
  final XpService?        xpService;

  const GamifiedLearningScreen({
    super.key,
    this.initialGame,
    this.lessonId,
    this.topicTitle      = 'Simulation',
    this.engineBaseUrl   = 'http://localhost:5176',
    this.progressService,
    this.xpService,
  });

  @override
  State<GamifiedLearningScreen> createState() => _GamifiedLearningScreenState();
}

enum _ScreenState { loading, ready, error, timeout }

class _GamifiedLearningScreenState extends State<GamifiedLearningScreen> {
  late final WebViewController _controller;
  late final ProgressService _progressService;
  late final XpService _xpService;

  _ScreenState _state        = _ScreenState.loading;
  String       _errorMessage = '';
  bool         _versionMismatch    = false;
  bool         _sessionInProgress  = false; // item 7: graceful update tracking

  // XP shown in AppBar – driven by XpService.
  int _displayXp = 0;

  Timer? _readyTimeoutTimer;
  int    _msgIdCounter = 0;
  String get _nextMsgId => '${++_msgIdCounter}';

  @override
  void initState() {
    super.initState();

    // Use injected services or create local singletons.
    _xpService       = widget.xpService ?? XpService();
    _progressService = widget.progressService
        ?? ProgressService(db: supabase, xpService: _xpService);

    _xpService.addListener(_onXpChanged);
    _buildController();
  }

  @override
  void dispose() {
    _readyTimeoutTimer?.cancel();
    _xpService.removeListener(_onXpChanged);
    super.dispose();
  }

  void _onXpChanged() {
    if (mounted) setState(() => _displayXp = _xpService.totalXp);
  }

  // ─── WebView construction ────────────────────────────────────────────────
  void _buildController() {
    final gameId = (widget.initialGame?.isNotEmpty == true)
        ? widget.initialGame!
        : 'INERTIA_BUS';

    // Item 8: whitelist only our engine domain by parsing the base URL.
    final engineUri = Uri.parse(widget.engineBaseUrl);

    var url = widget.engineBaseUrl;
    url += '/?embed=true&game=$gameId&theme=light';
    if (widget.lessonId?.isNotEmpty == true) {
      url += '&lesson=${widget.lessonId}';
    }

    _controller = WebViewController();
    
    if (!kIsWeb) {
      _controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Tailwind.slate50)
        ..addJavaScriptChannel(
          'FlutterBridge',
          onMessageReceived: (msg) => _handleReactMessage(msg.message),
        )
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (_) {
            setState(() => _state = _ScreenState.loading);
            _readyTimeoutTimer?.cancel();
            _readyTimeoutTimer = Timer(_readyTimeout, _onReadyTimeout);
          },
          onPageFinished: (_) async {
            await _sendHello();
            await _injectSupabaseSession();
          },
          onWebResourceError: (error) {
            _readyTimeoutTimer?.cancel();
            setState(() {
              _state        = _ScreenState.error;
              _errorMessage = 'Could not load simulation. Check your connection.\n\n'
                  '(${error.description})';
            });
          },
          // ── Item 8: restrict navigation to the engine origin ─────────────
          onNavigationRequest: (request) {
            final dest = Uri.tryParse(request.url);
            if (dest == null) return NavigationDecision.prevent;
            // Allow only our engine host.
            if (dest.host == engineUri.host) return NavigationDecision.navigate;
            // Any external link: log it and block.
            debugPrint('[WebView] Blocked navigation to: ${request.url}');
            return NavigationDecision.prevent;
          },
        ));
    } else {
      // On Web, we can't use the native bridge or delegates. Just load it.
      setState(() => _state = _ScreenState.ready);
    }

    _controller.loadRequest(Uri.parse(url));
  }

  // ─── Timeout ────────────────────────────────────────────────────────────
  void _onReadyTimeout() {
    if (_state != _ScreenState.ready && mounted) {
      setState(() {
        _state        = _ScreenState.timeout;
        _errorMessage = 'The simulation took too long to respond. Please retry.';
      });
    }
  }

  // ─── Flutter → React: HELLO with message id ─────────────────────────────
  Future<void> _sendHello() async {
    final id      = _nextMsgId;
    final payload = jsonEncode({
      'id':   id,
      'type': 'HELLO',
      'payload': {
        'version':  _flutterAppVersion,
        'protocol': _protocolVersion,
      },
    });
    await _controller.runJavaScript('window.postMessage($payload, "*");');
  }

  // ─── Flutter → React: Supabase session (in-memory only on React side) ───
  Future<void> _injectSupabaseSession() async {
    final session = supabase.auth.currentSession;
    if (session == null) return;

    final id      = _nextMsgId;
    final payload = jsonEncode({
      'id':   id,
      'type': 'SUPABASE_SESSION',
      'payload': {
        'access_token':  session.accessToken,
        'refresh_token': session.refreshToken,
      },
    });
    await _controller.runJavaScript('window.postMessage($payload, "*");');
  }

  // ─── Flutter → React: send fresh session on REQUEST_SESSION ─────────────
  Future<void> _respondWithFreshSession(String replyTo) async {
    // Refresh the Supabase session before forwarding.
    try {
      await supabase.auth.refreshSession();
    } catch (_) { /* best effort */ }
    final session = supabase.auth.currentSession;
    if (session == null) return;

    final payload = jsonEncode({
      'replyTo': replyTo,
      'type':    'SUPABASE_SESSION',
      'payload': {
        'access_token':  session.accessToken,
        'refresh_token': session.refreshToken,
      },
    });
    await _controller.runJavaScript('window.postMessage($payload, "*");');
  }

  // ─── React → Flutter message handler ────────────────────────────────────
  void _handleReactMessage(String raw) {
    try {
      final data    = jsonDecode(raw) as Map<String, dynamic>;
      final type    = data['type'] as String? ?? '';
      final payload = data['payload'] as Map<String, dynamic>?;
      final msgId   = data['id']    as String?;  // outbound id from React (for ACK)
      final replyTo = data['replyTo'] as String?; // item 2: response to our message

      // Handle ACK responses to our messages (e.g. HELLO, SUPABASE_SESSION)
      if (replyTo != null) {
        debugPrint('[Bridge] ACK received for message $replyTo');
        return;
      }

      _sessionInProgress = true; // Item 7: mark session active

      switch (type) {

        // ── Handshake ────────────────────────────────────────────────────
        case 'ENGINE_READY':
          _readyTimeoutTimer?.cancel();
          final engineProto = payload?['protocol'] as int? ?? 0;
          // Local only – used for logging and feature-flag checks.
          final caps = (payload?['capabilities'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList();

          setState(() {
            _versionMismatch = engineProto != _protocolVersion;
            _state           = _ScreenState.ready;
          });

          if (_versionMismatch) {
            final v = payload?['version'] as String? ?? '?';
            debugPrint('[Bridge] Protocol mismatch – Flutter=$_protocolVersion '
                'React=$engineProto (v$v). Capabilities: $caps');
          } else {
            debugPrint('[Bridge] Engine ready. Capabilities: $caps');
          }
          break;

        // ── Lifecycle ────────────────────────────────────────────────────
        case 'SIMULATION_LOADING':
          setState(() => _state = _ScreenState.loading);
          break;

        case 'SIMULATION_READY':
          _readyTimeoutTimer?.cancel();
          setState(() => _state = _ScreenState.ready);
          break;

        case 'SIMULATION_ERROR':
          _readyTimeoutTimer?.cancel();
          final err = payload?['error'] as String? ?? 'Unknown simulation error';
          debugPrint('[Bridge] SIMULATION_ERROR: $err');
          // TODO: FirebaseCrashlytics.instance.recordError(err, null, reason: 'sim_error');
          _sessionInProgress = false; // session ended abnormally
          setState(() {
            _state        = _ScreenState.error;
            _errorMessage = err;
          });
          break;

        // ── Auth ─────────────────────────────────────────────────────────
        case 'REQUEST_SESSION':
          // React needs a refreshed token. We respond with a fresh session.
          _respondWithFreshSession(msgId ?? '');
          break;

        // ── Progress ─────────────────────────────────────────────────────
        case 'GAME_COMPLETED':
          _sessionInProgress = false;
          _onGameCompleted(payload ?? {});
          break;

        case 'GAME_EXITED':
          _sessionInProgress = false;
          if (Navigator.canPop(context)) Navigator.pop(context);
          break;

        case 'REQUEST_HINT':
          _showNativeHintDialog();
          break;

        case 'ACK':
          debugPrint('[Bridge] ACK for ${payload?['replyTo']}');
          break;
      }
    } catch (e) {
      debugPrint('[Bridge] Failed to parse React message: $e\nRaw: $raw');
    }
  }

  // ─── Item 6: delegate to service layer ──────────────────────────────────
  Future<void> _onGameCompleted(Map<String, dynamic> payload) async {
    final analytics = GameAnalytics.fromJson({
      ...payload,
      'gameId':   payload['gameId']   ?? widget.initialGame ?? '',
      'lessonId': payload['lessonId'] ?? widget.lessonId    ?? '',
    });

    debugPrint('[Bridge] Game completed: $analytics');

    // All persistence + XP logic lives in ProgressService / XpService.
    final reward = await _progressService.recordCompletion(analytics);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration:  const Duration(seconds: 3),
        backgroundColor: Tailwind.emerald600,
        behavior:  SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '+${reward.xpEarned} XP  ·  +${reward.coinsEarned} coins',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Native hint dialog ──────────────────────────────────────────────────
  void _showNativeHintDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💡 Hint',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Try adjusting variables one at a time and observe the simulation.',
              style: TextStyle(fontSize: 15, color: Tailwind.slate600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Tailwind.indigo600),
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Retry ───────────────────────────────────────────────────────────────
  void _retry() {
    setState(() {
      _state          = _ScreenState.loading;
      _errorMessage   = '';
      _versionMismatch = false;
      _sessionInProgress = false;
    });
    _controller.reload();
  }

  // ─── Item 7: guard pop during active session ─────────────────────────────
  Future<bool> _onPopInvoked() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    // Warn if there is an active session that would be interrupted.
    if (_sessionInProgress && mounted) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Leave simulation?'),
          content: const Text(
              'Your current session will not be saved if you leave now.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Leave',
                style: TextStyle(color: Tailwind.rose500),
              ),
            ),
          ],
        ),
      );
      return leave ?? false;
    }
    return true;
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onPopInvoked();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Tailwind.slate50,
        appBar: _buildAppBar(),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Tailwind.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Tailwind.slate800),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.science_rounded, color: Tailwind.indigo600, size: 20),
          const SizedBox(width: 8),
          Text(
            widget.topicTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Tailwind.slate800,
              fontSize: 17,
            ),
          ),
          // Item 5: surface version mismatch badge via capabilities
          if (_versionMismatch) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Tailwind.amber500,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Update available',
                style: TextStyle(
                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      actions: [
        // Live XP badge driven by XpService
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Tailwind.amber200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: Tailwind.amber700, size: 16),
              const SizedBox(width: 4),
              Text(
                '$_displayXp XP',
                style: const TextStyle(
                  color: Tailwind.amber700,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_state == _ScreenState.loading) _LoadingOverlay(),
        if (_state == _ScreenState.error || _state == _ScreenState.timeout)
          _ErrorOverlay(
            message:   _errorMessage,
            isTimeout: _state == _ScreenState.timeout,
            onRetry:   _retry,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Tailwind.slate50,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                  color: Tailwind.indigo600, strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading simulation…',
              style: const TextStyle(
                  color: Tailwind.slate500,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  final String message;
  final bool isTimeout;
  final VoidCallback onRetry;

  const _ErrorOverlay({
    required this.message,
    required this.isTimeout,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Tailwind.slate50,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isTimeout ? Icons.timer_off_rounded : Icons.cloud_off_rounded,
              size: 52,
              color: Tailwind.slate400,
            ),
            const SizedBox(height: 20),
            Text(
              isTimeout
                  ? 'Simulation timed out'
                  : 'Could not load simulation',
              style: const TextStyle(
                color: Tailwind.slate800,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style:
                  const TextStyle(color: Tailwind.slate500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Tailwind.indigo600,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text(
                'Retry',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
