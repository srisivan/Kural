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
          // Share lives in the header, beside the other actions.
          IconButton(
            icon: shareBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: shareBusy
                ? null
                : () => todaysKural.whenData((data) => openShareSheet(data)),
          ),
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            tooltip: 'Explore',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExploreScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Choose daily chapter',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChapterPickerScreen()),
              );
            },
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
