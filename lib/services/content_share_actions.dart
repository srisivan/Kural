import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../models/card_content.dart';
import '../widgets/content_card.dart';

/// Shared share/download behaviour for any screen showing a [CardContent].
/// Both actions render the same clean [ContentCard] off-screen using whichever
/// interpretation the passed content carries (the one the user landed on).
mixin ContentShareActions<T extends StatefulWidget> on State<T> {
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

  Future<Uint8List> _renderCard(CardContent content) {
    return _controller.captureFromWidget(
      ContentCard(content: content),
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

  Future<void> _share(CardContent content) => _run(() async {
        final bytes = await _renderCard(content);
        final file = await _writeTemp(bytes, '${content.shareFileStem}.png');
        await Share.shareXFiles([XFile(file.path)], text: content.title);
      });

  Future<void> _download(CardContent content) => _run(() async {
        final bytes = await _renderCard(content);
        try {
          await Gal.putImageBytes(bytes, album: 'Kural');
          _snack('Saved to your gallery (Kural album)');
        } on GalException catch (e) {
          _snack('Could not save: ${e.type.message}');
        }
      });

  void openShareSheet(CardContent content) {
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
                _share(content);
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
                _download(content);
              },
            ),
          ],
        ),
      ),
    );
  }
}
