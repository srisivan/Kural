import 'kural.dart';
import 'chapter.dart';
import 'aathichudi.dart';

enum ContentKind { kural, aathichudi }

// Fixed daily carousel order: Solomon Pappaiya → Kalaignar → Varadarajan.
const List<String> kuralInterpretationKeys = ['sp', 'mk', 'mv'];
const Map<String, String> kuralInterpretationAuthors = {
  'mv': 'மு. வரதராசன்',
  'sp': 'சாலமன் பாப்பையா',
  'mk': 'கலைஞர் மு. கருணாநிதி',
};

/// A single swipeable interpretation panel.
class InterpretationEntry {
  final String header; // e.g. "பொருள்", "எளிய பொருள்", "Translation"
  final String text;
  final String? author; // shown as "— author" when present

  const InterpretationEntry({
    required this.header,
    required this.text,
    this.author,
  });
}

/// A text-agnostic bundle that drives the shared card, carousel, and share
/// pipeline. Both Thirukkural and Aathichudi build one of these, so every
/// screen and the sharing code work identically for either.
class CardContent {
  final ContentKind kind;
  final String title; // card heading: "திருக்குறள்" / "ஆத்திசூடி"
  final String poem; // the verse text (joined lines)
  final String? chapterName; // kural only
  final String metaLine; // "அதிகாரம் 40   ·   குறள் 391" / "ஆத்திசூடி 1"
  final List<InterpretationEntry> interpretations;
  final int selectedIndex;
  final int itemNumber;
  final String detailTitle; // app-bar title: "குறள் 391" / "ஆத்திசூடி 1"

  const CardContent({
    required this.kind,
    required this.title,
    required this.poem,
    required this.chapterName,
    required this.metaLine,
    required this.interpretations,
    required this.selectedIndex,
    required this.itemNumber,
    required this.detailTitle,
  });

  InterpretationEntry get selected => interpretations[selectedIndex];

  String get shareFileStem =>
      '${kind == ContentKind.kural ? 'kural' : 'aathichudi'}_$itemNumber';

  CardContent withIndex(int index) => CardContent(
        kind: kind,
        title: title,
        poem: poem,
        chapterName: chapterName,
        metaLine: metaLine,
        interpretations: interpretations,
        selectedIndex: index.clamp(0, interpretations.length - 1),
        itemNumber: itemNumber,
        detailTitle: detailTitle,
      );

  factory CardContent.fromKural(
    Kural kural,
    Chapter chapter, {
    int selectedIndex = 0,
  }) {
    final interps = kuralInterpretationKeys
        .map((k) => InterpretationEntry(
              header: 'பொருள்',
              text: kural.interpretation(k),
              author: kuralInterpretationAuthors[k],
            ))
        .toList();
    return CardContent(
      kind: ContentKind.kural,
      title: 'திருக்குறள்',
      poem: kural.combinedLines,
      chapterName: chapter.name,
      metaLine: 'அதிகாரம் ${chapter.number}   ·   குறள் ${kural.number}',
      interpretations: interps,
      selectedIndex: selectedIndex,
      itemNumber: kural.number,
      detailTitle: 'குறள் ${kural.number}',
    );
  }

  factory CardContent.fromAathichudi(
    Aathichudi a, {
    int selectedIndex = 0,
  }) {
    final interps = <InterpretationEntry>[
      InterpretationEntry(header: 'பொருள்', text: a.meaning),
      InterpretationEntry(header: 'எளிய பொருள்', text: a.paraphrase),
      if (a.translation.trim().isNotEmpty)
        InterpretationEntry(header: 'Translation', text: a.translation),
    ];
    return CardContent(
      kind: ContentKind.aathichudi,
      title: 'ஆத்திசூடி',
      poem: a.poem,
      chapterName: null,
      metaLine: 'ஆத்திசூடி ${a.number}',
      interpretations: interps,
      selectedIndex: selectedIndex,
      itemNumber: a.number,
      detailTitle: 'ஆத்திசூடி ${a.number}',
    );
  }
}
