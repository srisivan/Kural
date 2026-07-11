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
  int? _kuralIndex;
  int _aathiIndex = 0;

  int _kuralDefaultIndex(TodaysKural t) {
    final i = kuralInterpretationKeys.indexOf(t.interpretationKey);
    return i < 0 ? 0 : i;
  }

  Future<void> _sendTestNotification() async {
    final svc = ref.read(notificationServiceProvider);
    final enabled = await svc.notificationsEnabled();
    await svc.showTestNotification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(enabled
          ? 'Test sent — check your notification shade.'
          : 'Notifications are DISABLED for this app. Enable them in Settings → Apps → Kural → Notifications.'),
      duration: const Duration(seconds: 5),
    ));
  }

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
    final palette = paletteFor(!isKural);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        foregroundColor: palette.ink,
        titleSpacing: 12,
        title: _ModeTitleTile(
          title: isKural ? 'திருக்குறள்' : 'ஆத்திசூடி',
          palette: palette,
          onToggle: () => ref.read(contentModeProvider.notifier).toggle(),
        ),
        actions: [
          if (shareBusy)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: palette.ink),
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Menu',
              color: palette.background,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: palette.tileBorder),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'share':
                    final content = _currentContent();
                    if (content != null) openShareSheet(content, palette);
                    break;
                  case 'explore':
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ExploreScreen()));
                    break;
                  case 'chapter':
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ChapterPickerScreen()));
                    break;
                  case 'test':
                    _sendTestNotification();
                    break;
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'share',
                  child: _MenuRow(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      palette: palette),
                ),
                PopupMenuItem(
                  value: 'explore',
                  child: _MenuRow(
                      icon: Icons.explore_outlined,
                      label: 'Explore',
                      palette: palette),
                ),
                if (isKural)
                  PopupMenuItem(
                    value: 'chapter',
                    child: _MenuRow(
                        icon: Icons.menu_book_outlined,
                        label: 'Choose daily chapter',
                        palette: palette),
                  ),
                PopupMenuItem(
                  value: 'test',
                  child: _MenuRow(
                      icon: Icons.notifications_active_outlined,
                      label: 'Test notification',
                      palette: palette),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: isKural ? _buildKural(palette) : _buildAathichudi(palette),
      ),
    );
  }

  Widget _buildKural(ContentPalette palette) {
    final todays = ref.watch(todaysKuralProvider);
    return todays.when(
      loading: () => Center(
          child: CircularProgressIndicator(color: palette.ink)),
      error: (e, st) => _errorText('$e', palette),
      data: (t) {
        final index = _kuralIndex ?? _kuralDefaultIndex(t);
        final content =
            CardContent.fromKural(t.kural, t.chapter, selectedIndex: index);
        return Center(
          child: SingleChildScrollView(
            child: ContentCarouselView(
              content: content,
              palette: palette,
              onIndexChanged: (i) => setState(() => _kuralIndex = i),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAathichudi(ContentPalette palette) {
    final todays = ref.watch(todaysAathichudiProvider);
    return todays.when(
      loading: () => Center(
          child: CircularProgressIndicator(color: palette.ink)),
      error: (e, st) => _errorText('$e', palette),
      data: (a) {
        if (a.needsEndChoice || a.item == null) {
          return _EndOfSetPrompt(
            palette: palette,
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
              palette: palette,
              onIndexChanged: (i) => setState(() => _aathiIndex = i),
            ),
          ),
        );
      },
    );
  }

  Widget _errorText(String e, ContentPalette palette) => Center(
        child: Text('Error: $e', style: TextStyle(color: palette.inkA(0.7))),
      );
}

/// The translucent title chip in the header. Swipe or tap to switch texts.
class _ModeTitleTile extends StatelessWidget {
  final String title;
  final ContentPalette palette;
  final VoidCallback onToggle;
  const _ModeTitleTile(
      {required this.title, required this.palette, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      onHorizontalDragEnd: (_) => onToggle(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: palette.tileFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.tileBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: GoogleFonts.anekTamil(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: palette.ink)),
            const SizedBox(width: 8),
            Icon(Icons.swap_horiz, size: 18, color: palette.inkA(0.7)),
          ],
        ),
      ),
    );
  }
}

class _EndOfSetPrompt extends StatelessWidget {
  final ContentPalette palette;
  final ValueChanged<String> onChoose;
  const _EndOfSetPrompt({required this.palette, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, color: palette.ink, size: 48),
            const SizedBox(height: 16),
            Text(
              'ஆத்திசூடி முற்றிற்று!',
              style: GoogleFonts.anekTamil(
                  color: palette.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              "You've been through every aathichudi. What next?",
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.inkA(0.75)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.onAccent),
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
                  foregroundColor: palette.ink,
                  side: BorderSide(color: palette.inkA(0.5)),
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
  final ContentPalette palette;
  const _MenuRow(
      {required this.icon, required this.label, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: palette.ink),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: palette.ink)),
      ],
    );
  }
}
