import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Adds one short speech-recognition session to an editable text field.
class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({super.key, required this.controller, this.enabled = true, this.onChanged});
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _ready = false;
  bool _starting = false;
  String _beforeSpeech = '';

  Future<void> _toggle() async {
    if (_speech.isListening) {
      await _speech.stop();
      if (mounted) setState(() {});
      return;
    }
    setState(() => _starting = true);
    try {
      _ready = await _speech.initialize(
        onStatus: (_) { if (mounted) setState(() {}); },
        onError: (error) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice input stopped: ${error.errorMsg}')),
          );
        },
      );
      if (!_ready) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice input is unavailable. You can type your description instead.')),
        );
        return;
      }
      _beforeSpeech = widget.controller.text.trimRight();
      await _speech.listen(
        onResult: _onResult,
        listenMode: stt.ListenMode.dictation,
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 4),
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start voice input. Check microphone and speech permissions.')),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.trim();
    final text = [if (_beforeSpeech.isNotEmpty) _beforeSpeech, if (words.isNotEmpty) words].join(' ');
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onChanged?.call(text);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    unawaited(_speech.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listening = _speech.isListening;
    return IconButton(
      tooltip: listening
          ? 'Stop dictation'
          : 'Dictate text with your phone speech service; review before sending',
      onPressed: !widget.enabled || _starting ? null : _toggle,
      icon: _starting
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(listening ? Icons.mic : Icons.mic_none, color: listening ? Colors.red : null),
    );
  }
}
