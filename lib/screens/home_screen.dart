import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/card_content.dart';
import '../providers/kural_providers.dart';
import '../services/content_share_actions.dart';
import '../widgets/content_carousel_view.dart';
import '../theme.dart';
import 'chapter_picker_screen.dart';
import 'explore_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with ContentShareActions {
  // Interpretation index the user swiped to, per track.
  int? _kuralIndex;
  int _aathiIndex = 0;

  int _kuralDefaultIndex(TodaysKural t) {
    final i = kuralInterpretationKeys.indexOf(t.interpretationKey);
    return i < 0 ? 0 : i;
  }

  /// The content currently on screen — used when the user taps Share.
  CardContent? _currentContent() {
    final mode = ref.read(contentModeProvider);
    if (mode == 'kural') {
      final t = ref.read(todaysKuralProvider).valueOrNull;
      if (t == null) return null;
      final idx = _kuralIndex ?? _kuralDefaultIndex(t);
      return CardContent.fromKural(t.kural, t.chapter).withIndex(idx);
    } else {
      final a = ref.read(todaysAathichudiProvider).valueOrNull;
      if (a?.item == null) return null;
      return CardContent.fromAathichudi(a!.item!).withIndex(_aathiIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(contentModeProvider);
    final isKural = mode == 'kural';

    return Scaffold(
      backgroundColor: kBrandBlue,
      appBar: AppBar(
        backgroundColor: kBrandBlue,
        elevation: 0,
        foregroundColor: Colors.white,
        titleSpacing: 12,
        title: _ModeTitleTile(
          title: isKural ? 'திருக்குறள்' : 'ஆத்திசூடி',
          onToggle: () => ref.read(contentModeProvider.notifier).toggle(),
        ),
        actions: [
          if (shareBusy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Menu',
              onSelected: (value) {
                switch (value) {
                  case 'share':
                    final content = _currentContent();
                    if (content != null) openShareSheet(content);
                    break;
                  case 'explore':
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ExploreScreen()));
                    break;
                  case 'chapter':
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ChapterPickerScreen()));
                    break;
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'share',
                  child: _MenuRow(icon: Icons.share_outlined, label: 'Share'),
                ),
                const PopupMenuItem(
                  value: 'explore',
                  child:
                      _MenuRow(icon: Icons.explore_outlined, label: 'Explore'),
                ),
                if (isKural)
                  const PopupMenuItem(
                    value: 'chapter',
                    child: _MenuRow(
                        icon: Icons.menu_book_outlined,
                        label: 'Choose daily chapter'),
                  ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: isKural ? _buildKural() : _buildAathichudi(),
      ),
    );
  }

  Widget _buildKural() {
    final todays = ref.watch(todaysKuralProvider);
    return todays.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, st) => _errorText('$e'),
      data: (t) {
        final index = _kuralIndex ?? _kuralDefaultIndex(t);
        final content = CardContent.fromKural(t.kural, t.chapter, selectedIndex: index);
        return Center(
          child: SingleChildScrollView(
            child: ContentCarouselView(
              content: content,
              onIndexChanged: (i) => setState(() => _kuralIndex = i),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAathichudi() {
    final todays = ref.watch(todaysAathichudiProvider);
    return todays.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, st) => _errorText('$e'),
      data: (a) {
        if (a.needsEndChoice || a.item == null) {
          return _EndOfSetPrompt(
            onChoose: (m) =>
                ref.read(todaysAathichudiProvider.notifier).chooseEndMode(m),
          );
        }
        final content =
            CardContent.fromAathichudi(a.item!, selectedIndex: _aathiIndex);
        return Center(
          child: SingleChildScrollView(
            child: ContentCarouselView(
              content: content,
              onIndexChanged: (i) => setState(() => _aathiIndex = i),
            ),
          ),
        );
      },
    );
  }

  Widget _errorText(String e) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: Colors.white70)),
      );
}

/// The translucent title chip in the header. Swipe or tap to switch texts.
class _ModeTitleTile extends StatelessWidget {
  final String title;
  final VoidCallback onToggle;
  const _ModeTitleTile({required this.title, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      onHorizontalDragEnd: (_) => onToggle(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: kTileFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kTileBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: GoogleFonts.anekTamil(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Icon(Icons.swap_horiz,
                size: 18, color: Colors.white.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}

class _EndOfSetPrompt extends StatelessWidget {
  final ValueChanged<String> onChoose;
  const _EndOfSetPrompt({required this.onChoose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined,
                color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              'ஆத்திசூடி முற்றிற்று!',
              style: GoogleFonts.anekTamil(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              "You've been through every aathichudi. What next?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.75)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: kBrandBlue),
                icon: const Icon(Icons.replay),
                label: const Text('Repeat from the start'),
                onPressed: () => onChoose('repeat'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.5)),
                ),
                icon: const Icon(Icons.shuffle),
                label: const Text('Randomize each day'),
                onPressed: () => onChoose('random'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row (icon + label) used for the header menu items.
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
