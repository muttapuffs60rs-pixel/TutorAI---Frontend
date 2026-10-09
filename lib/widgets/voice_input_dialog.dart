import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

// The platform recognizer is initialized once; callbacks follow the active panel.
class _Recognizer {
  static final speech = SpeechToText();
  static void Function(String)? status;
  static void Function(String)? error;
  static Future<bool> initialize() => speech.initialize(
    onStatus: (value) => status?.call(value),
    onError: (value) => error?.call(value.errorMsg),
    options: [SpeechToText.androidNoBluetooth],
  );
}

class VoiceInputDialog extends StatefulWidget {
  const VoiceInputDialog({super.key});
  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  String _language = 'ta-IN';
  String _prefix = '';
  String? _error;
  bool _listening = false;
  bool _busy = true;
  bool _acceptResults = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLanguage();
    _Recognizer.status = (status) {
      if (mounted && (status == 'done' || status == 'notListening')) {
        setState(() => _listening = false);
      }
    };
    _Recognizer.error = (error) {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _busy = false;
        _error = error.contains('permission') || error.contains('denied')
            ? 'Microphone access was denied. Enable it in your device or browser settings, or type your question.'
            : error.contains('no_match') || error.contains('timeout')
            ? 'No speech detected. Try again and speak clearly.'
            : 'Voice input could not finish. Check your connection and microphone, or type your question.';
      });
    };
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('voice_input_language');
      if (mounted)
        setState(() => _language = saved == 'en-IN' ? 'en-IN' : 'ta-IN');
    } catch (_) {
      // Keep Tamil available when local preference storage is unavailable.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final available = await _Recognizer.initialize();
      if (!mounted) return;
      if (!available) {
        setState(
          () => _error =
              'Voice input is unavailable or microphone access is blocked. Try a supported browser or use the keyboard.',
        );
        return;
      }
      final locales = await _Recognizer.speech.locales();
      if (!mounted) return;
      final language = _language.split('-').first;
      final matches = locales
          .where(
            (l) => l.localeId.replaceAll('_', '-').startsWith('$language-'),
          )
          .toList();
      if (locales.isNotEmpty && matches.isEmpty) {
        setState(
          () => _error =
              'This device does not offer the selected speech language. Enable it in your speech settings or choose another language.',
        );
        return;
      }
      final exact = matches.where(
        (l) => l.localeId.replaceAll('_', '-') == _language,
      );
      final locale = exact.isNotEmpty
          ? exact.first.localeId
          : matches.isNotEmpty
          ? matches.first.localeId
          : _language;
      _prefix = _text.text.trimRight();
      _acceptResults = true;
      setState(() => _listening = true);
      await _Recognizer.speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: locale,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
        onResult: (result) {
          if (!mounted || !_acceptResults) return;
          final words = result.recognizedWords;
          final value = [_prefix, words].where((s) => s.isNotEmpty).join(' ');
          setState(() {
            _text.value = TextEditingValue(
              text: value,
              selection: TextSelection.collapsed(offset: value.length),
            );
          });
        },
      );
    } catch (_) {
      if (mounted)
        setState(() {
          _listening = false;
          _error =
              'Unable to start voice input. You can still type your question.';
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    await _Recognizer.speech.stop();
    _acceptResults = false;
    if (mounted) setState(() => _listening = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _acceptResults = false;
      _Recognizer.speech.cancel();
      if (mounted) setState(() => _listening = false);
    }
  }

  @override
  void dispose() {
    _acceptResults = false;
    _Recognizer.status = null;
    _Recognizer.error = null;
    _Recognizer.speech.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Speak your question'),
    scrollable: true,
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _language,
            key: ValueKey(_language),
            decoration: const InputDecoration(labelText: 'Speech language'),
            items: const [
              DropdownMenuItem(value: 'ta-IN', child: Text('தமிழ் (Tamil)')),
              DropdownMenuItem(value: 'en-IN', child: Text('English')),
            ],
            onChanged: _listening || _busy
                ? null
                : (value) async {
                    if (value == null) return;
                    setState(() => _language = value);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('voice_input_language', value);
                  },
          ),
          const SizedBox(height: 12),
          const Text(
            'Speak, review the text, then add it to your message. Nothing is sent automatically. Your device’s speech service may process audio online.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : _listening
                ? _stop
                : _start,
            icon: Icon(_listening ? Icons.stop : Icons.mic),
            label: Text(
              _busy
                  ? 'Getting ready…'
                  : _listening
                  ? 'Stop listening'
                  : 'Start speaking',
            ),
          ),
          if (_listening)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Listening…',
                semanticsLabel: 'Microphone is listening',
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            readOnly: _listening || _busy,
            minLines: 3,
            maxLines: 6,
            onChanged: (_) { _acceptResults = false; setState(() {}); },
            decoration: const InputDecoration(
              labelText: 'Review your text',
              hintText: 'Your words will appear here',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _busy || _listening || _text.text.trim().isEmpty
            ? null
            : () {
                _acceptResults = false;
                Navigator.pop(context, _text.text.trim());
              },
        child: const Text('Add to message'),
      ),
    ],
  );
}
