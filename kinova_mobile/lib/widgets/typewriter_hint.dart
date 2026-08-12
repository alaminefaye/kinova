import 'dart:async';

import 'package:flutter/material.dart';

/// Placeholder animé : écrit le texte, pause, efface, recommence (boucle).
class TypewriterHint extends StatefulWidget {
  const TypewriterHint({
    super.key,
    required this.phrases,
    this.style,
    this.typingSpeed = const Duration(milliseconds: 55),
    this.deletingSpeed = const Duration(milliseconds: 28),
    this.pauseAtEnd = const Duration(milliseconds: 1600),
    this.pauseAtStart = const Duration(milliseconds: 400),
    this.showCursor = true,
  });

  final List<String> phrases;
  final TextStyle? style;
  final Duration typingSpeed;
  final Duration deletingSpeed;
  final Duration pauseAtEnd;
  final Duration pauseAtStart;
  final bool showCursor;

  @override
  State<TypewriterHint> createState() => _TypewriterHintState();
}

class _TypewriterHintState extends State<TypewriterHint> {
  int _phraseIndex = 0;
  int _charIndex = 0;
  bool _deleting = false;
  bool _cursorOn = true;
  Timer? _typeTimer;
  Timer? _cursorTimer;

  String get _currentPhrase =>
      widget.phrases.isEmpty ? '' : widget.phrases[_phraseIndex];

  @override
  void initState() {
    super.initState();
    _scheduleNext(widget.pauseAtStart);
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 480), (_) {
      if (!mounted || !widget.showCursor) return;
      setState(() => _cursorOn = !_cursorOn);
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  void _scheduleNext(Duration delay) {
    _typeTimer?.cancel();
    _typeTimer = Timer(delay, _tick);
  }

  void _tick() {
    if (!mounted || widget.phrases.isEmpty) return;

    final phrase = _currentPhrase;

    if (!_deleting) {
      if (_charIndex < phrase.length) {
        setState(() => _charIndex++);
        _scheduleNext(widget.typingSpeed);
      } else {
        _deleting = true;
        _scheduleNext(widget.pauseAtEnd);
      }
      return;
    }

    if (_charIndex > 0) {
      setState(() => _charIndex--);
      _scheduleNext(widget.deletingSpeed);
      return;
    }

    _deleting = false;
    _phraseIndex = (_phraseIndex + 1) % widget.phrases.length;
    _scheduleNext(widget.pauseAtStart);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _currentPhrase.substring(0, _charIndex.clamp(0, _currentPhrase.length));
    final cursor = widget.showCursor && _cursorOn ? '|' : ' ';

    return Text(
      '$visible$cursor',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );
  }
}
