class Chapter {
  final int number; // global chapter number (1-133)
  final String name; // Tamil name
  final String translation;
  final String transliteration;
  final int start; // first kural number in this chapter
  final int end; // last kural number in this chapter
  final String sectionName; // e.g. அறத்துப்பால் / Virtue
  final String chapterGroupName; // e.g. பாயிரவியல் / Prologue

  Chapter({
    required this.number,
    required this.name,
    required this.translation,
    required this.transliteration,
    required this.start,
    required this.end,
    required this.sectionName,
    required this.chapterGroupName,
  });

  /// Parses the full nested chapters.json structure (as shown in the prompt:
  /// root -> section.detail[] -> chapterGroup.detail[] -> chapters.detail[])
  /// into a flat list of Chapter objects, in kural order.
  static List<Chapter> parseNested(Map<String, dynamic> root) {
    final List<Chapter> result = [];

    final section = root['section'];
    final sectionDetails = section['detail'] as List<dynamic>;

    for (final sec in sectionDetails) {
      final sectionTranslation = sec['translation'] ?? '';
      final chapterGroup = sec['chapterGroup'];
      final groupDetails = chapterGroup['detail'] as List<dynamic>;

      for (final group in groupDetails) {
        final groupName = group['name'] ?? '';
        final chapters = group['chapters'];
        final chapterDetails = chapters['detail'] as List<dynamic>;

        for (final ch in chapterDetails) {
          result.add(Chapter(
            number: ch['number'] as int,
            name: ch['name'] ?? '',
            translation: ch['translation'] ?? '',
            transliteration: ch['transliteration'] ?? '',
            start: ch['start'] as int,
            end: ch['end'] as int,
            sectionName: sectionTranslation,
            chapterGroupName: groupName,
          ));
        }
      }
    }

    result.sort((a, b) => a.number.compareTo(b.number));
    return result;
  }
}
