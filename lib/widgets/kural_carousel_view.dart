import 'package:flutter/material.dart';
import '../models/kural.dart';
import '../providers/kural_providers.dart';
import '../theme.dart';
import 'kural_card.dart';

/// The on-screen kural view: the kural tile plus a swipeable interpretation.
/// The interpretation the user swipes to is reported via [onKeyChanged] so the
/// screen can share/download that same one.
class KuralCarouselView extends StatelessWidget {
  final TodaysKural data;
  final String selectedKey;
  final ValueChanged<String> onKeyChanged;

  const KuralCarouselView({
    super.key,
    required this.data,
    required this.selectedKey,
    required this.onKeyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBrandBlue,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KuralTile(view: data),
          const SizedBox(height: 18),
          InterpretationCarousel(
            // Reset when the kural itself changes.
            key: ValueKey(data.kural.number),
            kural: data.kural,
            initialKey: selectedKey,
            onKeyChanged: onKeyChanged,
          ),
        ],
      ),
    );
  }
}

/// Swipe left/right to move between the three interpretations. The tile sizes
/// to its content (no fixed height, no bottom controls) so the full
/// explanation is always visible.
class InterpretationCarousel extends StatefulWidget {
  final Kural kural;
  final String initialKey;
  final ValueChanged<String> onKeyChanged;

  const InterpretationCarousel({
    super.key,
    required this.kural,
    required this.initialKey,
    required this.onKeyChanged,
  });

  @override
  State<InterpretationCarousel> createState() => _InterpretationCarouselState();
}

class _InterpretationCarouselState extends State<InterpretationCarousel> {
  late int _index;
  // +1 when moving forward, -1 when moving back — drives the slide direction.
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _index = interpretationKeys.indexOf(widget.initialKey);
    if (_index < 0) _index = 0;
  }

  void _move(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= interpretationKeys.length) return;
    setState(() {
      _direction = delta;
      _index = next;
    });
    widget.onKeyChanged(interpretationKeys[_index]);
  }

  @override
  Widget build(BuildContext context) {
    final key = interpretationKeys[_index];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < 0) {
          _move(1); // swipe left → next
        } else if (v > 0) {
          _move(-1); // swipe right → previous
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final incoming = child.key == ValueKey(_index);
          final beginX = incoming ? _direction * 0.12 : -_direction * 0.12;
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(beginX, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        child: InterpretationTile(
          key: ValueKey(_index),
          interpretationKey: key,
          text: widget.kural.interpretation(key),
        ),
      ),
    );
  }
}
