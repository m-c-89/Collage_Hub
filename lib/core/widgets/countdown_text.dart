import 'dart:async';
import 'package:flutter/material.dart';

class CountdownText extends StatefulWidget {
  final DateTime deadline;
  final TextStyle? style;

  const CountdownText(
    this.deadline, {
    super.key,
    this.style,
  });

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadline != widget.deadline) {
      _timer?.cancel();
      _startTimerIfNeeded();
    }
  }

  void _startTimerIfNeeded() {
    final now = DateTime.now();
    if (now.isBefore(widget.deadline)) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (!DateTime.now().isBefore(widget.deadline)) {
          timer.cancel();
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remainingSeconds = widget.deadline.difference(now).inSeconds;
    final totalSeconds = remainingSeconds > 0 ? remainingSeconds : 0;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    return Text(
      '$minutes:$seconds',
      style: widget.style,
    );
  }
}
