import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/kural_providers.dart';
import '../widgets/kural_card.dart';
import '../theme.dart';
import 'chapter_picker_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _sharing = false;

  Future<void> _share(BuildContext context) async {
    setState(() => _sharing = true);
    try {
      final bytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = await File('${dir.path}/kural_share.png').create();
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Thirukkural of the day');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todaysKural = ref.watch(todaysKuralProvider);

    return Scaffold(
      backgroundColor: kDeepBlue,
      appBar: AppBar(
        backgroundColor: kDeepBlue,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text('Thirukkural', style: GoogleFonts.anekTamil()),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Choose chapter',
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('Error: $err')),
          data: (data) => Center(
            child: SingleChildScrollView(
              child: Screenshot(
                controller: _screenshotController,
                child: KuralCard(data: data),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: todaysKural.maybeWhen(
        data: (_) => FloatingActionButton.extended(
          onPressed: _sharing ? null : () => _share(context),
          icon: _sharing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.share),
          label: Text(_sharing ? 'Preparing...' : 'Share'),
          backgroundColor: Colors.white,
          foregroundColor: kDeepBlue,
        ),
        orElse: () => null,
      ),
    );
  }
}
