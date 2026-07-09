import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../providers/kural_providers.dart';
import '../widgets/kural_card.dart';

/// Shared share/download behaviour for any screen that shows a kural.
///
/// Both actions render the same clean [KuralCard] off-screen (so carousel
/// arrows never appear in the image) using whatever interpretation the passed
/// [TodaysKural] carries — i.e. the one the user landed on in the carousel.
mixin KuralShareActions<T extends StatefulWidget> on State<T> {
  final ScreenshotController _controller = ScreenshotController();
  bool shareBusy = false;

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

  /// Renders the shareable card image. A generous target height lets the card
  /// size to its content (the boundary captures only the card, not the whole
  /// canvas), giving a consistent ~1200px-wide image on any device.
  Future<Uint8List> _renderCard(TodaysKural data) {
    return _controller.captureFromWidget(
      KuralCard(data: data),
      context: context,
      targetSize: const Size(400, 3000),
      pixelRatio: 3.0,
      delay: const Duration(milliseconds: 50),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (shareBusy) return;
    setState(() => shareBusy = true);
    try {
      await action();
    } catch (e) {
      _snack('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => shareBusy = false);
    }
  }

  Future<void> _share(TodaysKural data) => _run(() async {
        final bytes = await _renderCard(data);
        final file = await _writeTemp(bytes, 'kural_${data.kural.number}.png');
        await Share.shareXFiles([XFile(file.path)],
            text: 'திருக்குறள் ${data.kural.number}');
      });

  Future<void> _download(TodaysKural data) => _run(() async {
        final bytes = await _renderCard(data);
        try {
          await Gal.putImageBytes(bytes, album: 'Kural');
          _snack('Saved to your gallery (Kural album)');
        } on GalException catch (e) {
          _snack('Could not save: ${e.type.message}');
        }
      });

  void openShareSheet(TodaysKural data) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              iconColor: Colors.white,
              textColor: Colors.white,
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              subtitle: Text('Post as a WhatsApp status, or send anywhere',
                  style: TextStyle(color: Colors.white.withOpacity(0.6))),
              onTap: () {
                Navigator.pop(ctx);
                _share(data);
              },
            ),
            ListTile(
              iconColor: Colors.white,
              textColor: Colors.white,
              leading: const Icon(Icons.download_outlined),
              title: const Text('Download'),
              subtitle: Text('Save the card to your gallery',
                  style: TextStyle(color: Colors.white.withOpacity(0.6))),
              onTap: () {
                Navigator.pop(ctx);
                _download(data);
              },
            ),
          ],
        ),
      ),
    );
  }
}
