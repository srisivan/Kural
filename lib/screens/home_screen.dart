import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gal/gal.dart';
import '../providers/kural_providers.dart';
import '../widgets/kural_card.dart';
import '../widgets/whatsapp_status_card.dart';
import '../theme.dart';
import 'chapter_picker_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _busy = false;

  Future<File> _writeTemp(Uint8List bytes, String name) async {
    final dir = await getTemporaryDirectory();
    final file = await File('${dir.path}/$name').create();
    await file.writeAsBytes(bytes);
    return file;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Captures the tall on-screen card as shown.
  Future<Uint8List?> _captureScreenCard() =>
      _screenshotController.capture(pixelRatio: 3.0);

  /// Renders the rectangular status card off-screen and captures it.
  Future<Uint8List> _captureStatusCard(TodaysKural data) {
    return _screenshotController.captureFromWidget(
      WhatsAppStatusCard(data: data),
      context: context,
      targetSize: WhatsAppStatusCard.canvasSize,
      pixelRatio: 1.0,
      delay: const Duration(milliseconds: 50),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _snack('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareScreenCard(TodaysKural data) => _run(() async {
        final bytes = await _captureScreenCard();
        if (bytes == null) return;
        final file = await _writeTemp(bytes, 'kural_${data.kural.number}.png');
        await Share.shareXFiles([XFile(file.path)],
            text: 'திருக்குறள் ${data.kural.number}');
      });

  Future<void> _shareStatusCard(TodaysKural data) => _run(() async {
        final bytes = await _captureStatusCard(data);
        final file =
            await _writeTemp(bytes, 'kural_status_${data.kural.number}.png');
        await Share.shareXFiles([XFile(file.path)],
            text: 'திருக்குறள் ${data.kural.number}');
      });

  Future<void> _downloadCard(TodaysKural data) => _run(() async {
        final bytes = await _captureScreenCard();
        if (bytes == null) return;
        try {
          await Gal.putImageBytes(bytes, album: 'Kural');
          _snack('Saved to your gallery (Kural album)');
        } on GalException catch (e) {
          _snack('Could not save: ${e.type.message}');
        }
      });

  void _openShareSheet(TodaysKural data) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Share image'),
              subtitle: const Text('The full kural card'),
              onTap: () {
                Navigator.pop(ctx);
                _shareScreenCard(data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.crop_portrait_outlined),
              title: const Text('WhatsApp Status'),
              subtitle: const Text('A rectangular card to post as your status'),
              onTap: () {
                Navigator.pop(ctx);
                _shareStatusCard(data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Download image'),
              subtitle: const Text('Save the card to your gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _downloadCard(data);
              },
            ),
          ],
        ),
      ),
    );
  }

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
          // Share lives in the header, beside the chapter (book) icon.
          IconButton(
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: _busy
                ? null
                : () => todaysKural.whenData((data) => _openShareSheet(data)),
          ),
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
          loading: () =>
              const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (err, st) => Center(
            child: Text('Error: $err',
                style: const TextStyle(color: Colors.white70)),
          ),
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
    );
  }
}
