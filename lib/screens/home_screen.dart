import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/kural_providers.dart';
import '../services/kural_share_actions.dart';
import '../widgets/kural_card.dart';
import '../theme.dart';
import 'chapter_picker_screen.dart';
import 'explore_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with KuralShareActions {
  @override
  Widget build(BuildContext context) {
    final todaysKural = ref.watch(todaysKuralProvider);

    return Scaffold(
      backgroundColor: kBrandBlue,
      appBar: AppBar(
        backgroundColor: kBrandBlue,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text('திருக்குறள்', style: GoogleFonts.anekTamil()),
        actions: [
          // All actions live behind a single header menu.
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
                    todaysKural.whenData((data) => openShareSheet(data));
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
              itemBuilder: (ctx) => const [
                PopupMenuItem(
                  value: 'share',
                  child: _MenuRow(
                      icon: Icons.share_outlined, label: 'Share'),
                ),
                PopupMenuItem(
                  value: 'explore',
                  child: _MenuRow(
                      icon: Icons.explore_outlined, label: 'Explore'),
                ),
                PopupMenuItem(
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
        child: todaysKural.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white)),
          error: (err, st) => Center(
            child: Text('Error: $err',
                style: const TextStyle(color: Colors.white70)),
          ),
          data: (data) => Center(
            child: SingleChildScrollView(
              child: Screenshot(
                controller: screenCaptureController,
                child: KuralCard(data: data),
              ),
            ),
          ),
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
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
