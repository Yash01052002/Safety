import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The large, always-reachable SOS button. Press-and-hold to arm, to avoid
/// accidental single-tap triggers.
class SosButton extends StatefulWidget {
  const SosButton({
    super.key,
    required this.onTriggered,
    this.holdDuration = const Duration(milliseconds: 600),
  });

  final VoidCallback onTriggered;
  final Duration holdDuration;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onTriggered();
        _hold.reset();
      }
    });

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hold.forward(),
      onTapUp: (_) => _hold.reset(),
      onTapCancel: () => _hold.reset(),
      child: AnimatedBuilder(
        animation: _hold,
        builder: (context, _) {
          return Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [AppTheme.emergencyRed, AppTheme.emergencyRedDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.emergencyRed.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: _hold.value * 12,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 210,
                  height: 210,
                  child: CircularProgressIndicator(
                    value: _hold.value,
                    strokeWidth: 6,
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                  ),
                ),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 48),
                    SizedBox(height: 8),
                    Text('HOLD FOR SOS',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
