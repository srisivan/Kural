import 'package:flutter/material.dart';
import '../models/card_content.dart';
import '../theme.dart';
import 'content_card.dart';

/// The on-screen view: the verse tile plus a swipeable / arrow-navigable
/// interpretation. The index the user lands on is reported via
/// [onIndexChanged] so the screen shares/downloads that same one.
class ContentCarouselView extends StatelessWidget {
  final CardContent content;
  final ValueChanged<int> onIndexChanged;

  const ContentCarouselView({
    super.key,
    required this.content,
    required this.onIndexChanged,
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
          PoemTile(content: content),
          const SizedBox(height: 18),
          InterpretationCarousel(
            key: ValueKey('${content.kind}_${content.itemNumber}'),
            interpretations: content.interpretations,
            initialIndex: content.selectedIndex,
            onIndexChanged: onIndexChanged,
          ),
        ],
      ),
    );
  }
}

/// Swipe or tap the small side arrows to move between interpretations. The
/// tile sizes to its content (no fixed height) so the full text is visible;
/// navigation loops from the last back to the first.
class InterpretationCarousel extends StatefulWidget {
  final List<InterpretationEntry> interpretations;
  final int initialIndex;
  final ValueChanged<int> onIndexChanged;

  const InterpretationCarousel({
    super.key,
    required this.interpretations,
    required this.initialIndex,
    required this.onIndexChanged,
  });

  @override
  State<InterpretationCarousel> createState() => _InterpretationCarouselState();
}

class _InterpretationCarouselState extends State<InterpretationCarousel> {
  late int _index;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.interpretations.length - 1);
  }

  void _move(int delta) {
    final count = widget.interpretations.length;
    if (count <= 1) return;
    setState(() {
      _direction = delta;
      _index = (_index + delta) % count; // loops both directions
      if (_index < 0) _index += count;
    });
    widget.onIndexChanged(_index);
  }

  @override
  Widget build(BuildContext context) {
    final multiple = widget.interpretations.length > 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (multiple) _arrow(Icons.chevron_left, () => _move(-1)),
        Expanded(
          child: GestureDetector(
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
                final beginX =
                    incoming ? _direction * 0.12 : -_direction * 0.12;
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
                entry: widget.interpretations[_index],
              ),
            ),
          ),
        ),
        if (multiple) _arrow(Icons.chevron_right, () => _move(1)),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      iconSize: 22,
      splashRadius: 20,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
      icon: Icon(icon, color: Colors.white.withOpacity(0.75)),
    );
  }
}
