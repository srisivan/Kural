import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/card_content.dart';
import '../services/content_share_actions.dart';
import '../widgets/content_carousel_view.dart';
import '../theme.dart';

/// Read-only detail view for a single kural or aathichudi (reached from
/// Explore). Same look, carousel, and share/download as the daily screen —
/// and the palette follows the text (blue for kural, cream for aathichudi).
class ContentDetailScreen extends StatefulWidget {
  final CardContent content;
  const ContentDetailScreen({super.key, required this.content});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen>
    with ContentShareActions {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.content.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.content.withIndex(_index);
    final palette = paletteFor(content.kind == ContentKind.aathichudi);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        foregroundColor: palette.ink,
        elevation: 0,
        title: Text(content.detailTitle, style: GoogleFonts.anekTamil()),
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
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share',
              onPressed: () => openShareSheet(content, palette),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ContentCarouselView(
              content: content,
              palette: palette,
              onIndexChanged: (i) => setState(() => _index = i),
            ),
          ),
        ),
      ),
    );
  }
}
