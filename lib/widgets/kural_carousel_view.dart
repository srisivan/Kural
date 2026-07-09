import 'package:flutter/material.dart';
import '../models/kural.dart';
import '../providers/kural_providers.dart';
import '../theme.dart';
import 'kural_card.dart';

/// The on-screen kural view: the kural tile plus a swipeable carousel of the
/// three interpretations. The page the user lands on is reported via
/// [onKeyChanged] so the screen can share/download that same interpretation.
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
            // Reset the carousel when the kural itself changes.
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

/// Swipeable / arrow-navigable carousel over the three interpretations.
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
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = interpretationKeys.indexOf(widget.initialKey);
    if (_index < 0) _index = 0;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _controller,
            itemCount: interpretationKeys.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              widget.onKeyChanged(interpretationKeys[i]);
            },
            itemBuilder: (context, i) {
              final key = interpretationKeys[i];
              return SingleChildScrollView(
                child: InterpretationTile(
                  interpretationKey: key,
                  text: widget.kural.interpretation(key),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _arrow(Icons.chevron_left, _index > 0, () => _goTo(_index - 1)),
            const SizedBox(width: 4),
            for (int i = 0; i < interpretationKeys.length; i++) _dot(i == _index),
            const SizedBox(width: 4),
            _arrow(Icons.chevron_right,
                _index < interpretationKeys.length - 1, () => _goTo(_index + 1)),
          ],
        ),
      ],
    );
  }

  Widget _arrow(IconData icon, bool enabled, VoidCallback onTap) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      splashRadius: 22,
      icon: Icon(
        icon,
        color: enabled ? Colors.white : Colors.white.withOpacity(0.22),
      ),
    );
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
