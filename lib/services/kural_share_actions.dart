import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../providers/kural_providers.dart';
import '../widgets/whatsapp_status_card.dart';

/// Shared share/download behaviour for any screen that shows a kural.
///
/// The host screen must wrap its on-screen card in
/// `Screenshot(controller: screenCaptureController, child: ...)`.
/// - "Share image" captures whatever card is on screen.
/// - "WhatsApp Status" and "Download" both use the compact rectangular
///   status card, rendered off-screen.
mixin KuralShareActions<T extends StatefulWidget> on State<T> {
  final ScreenshotController screenCaptureController = ScreenshotController();
  final ScreenshotController _statusController = ScreenshotController();
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

  Future<Uint8List?> _captureScreenCard() =>
      screenCaptureController.capture(pixelRatio: 3.0);

  Future<Uint8List> _captureStatusCard(TodaysKural data) {
    return _statusController.captureFromWidget(
      WhatsAppStatusCard(data: data),
      context: context,
      targetSize: WhatsAppStatusCard.canvasSize,
      pixelRatio: 1.0,
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

  // Download saves the compact WhatsApp-status card (not the full screen one).
  Future<void> _downloadStatusCard(TodaysKural data) => _run(() async {
        final bytes = await _captureStatusCard(data);
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
              subtitle: const Text('Save the status card to your gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _downloadStatusCard(data);
              },
            ),
          ],
        ),
      ),
    );
  }
}
