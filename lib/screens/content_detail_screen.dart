import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/card_content.dart';
import '../services/content_share_actions.dart';
import '../widgets/content_carousel_view.dart';
import '../theme.dart';

/// Read-only detail view for a single kural or aathichudi (reached from
/// Explore). Same look, carousel, and share/download as the daily screen.
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

    return Scaffold(
      backgroundColor: kBrandBlue,
      appBar: AppBar(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(content.detailTitle, style: GoogleFonts.anekTamil()),
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
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share',
              onPressed: () => openShareSheet(content),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ContentCarouselView(
              content: content,
              onIndexChanged: (i) => setState(() => _index = i),
            ),
          ),
        ),
      ),
    );
  }
}
