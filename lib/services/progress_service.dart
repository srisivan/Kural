import 'package:hive_flutter/hive_flutter.dart';

/// Wraps a single Hive box that tracks reading progress.
/// Keys:
///   selectedChapter      -> int   (global chapter number)
///   lastServedKuralNum   -> int
///   lastServedDate       -> String 'yyyy-MM-dd'
///   lastInterpretation   -> String 'mv' | 'sp' | 'mk'
class ProgressService {
  static const String boxName = 'progress';
  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(boxName);
  }

  int? get selectedChapter => _box.get('selectedChapter') as int?;
  Future<void> setSelectedChapter(int chapterNumber) async {
    await _box.put('selectedChapter', chapterNumber);
    // Starting a new chapter resets progress within it.
    await _box.delete('lastServedKuralNum');
    await _box.delete('lastServedDate');
  }

  /// Updates which chapter we're currently in WITHOUT resetting progress.
  /// Used when the daily flow crosses from one chapter into the next.
  Future<void> syncCurrentChapter(int chapterNumber) async {
    await _box.put('selectedChapter', chapterNumber);
  }

  int? get lastServedKuralNumber => _box.get('lastServedKuralNum') as int?;
  String? get lastServedDate => _box.get('lastServedDate') as String?;
  String? get lastInterpretation => _box.get('lastInterpretation') as String?;

  Future<void> saveServed({
    required int kuralNumber,
    required String date,
    required String interpretationKey,
  }) async {
    await _box.put('lastServedKuralNum', kuralNumber);
    await _box.put('lastServedDate', date);
    await _box.put('lastInterpretation', interpretationKey);
  }

  // ---- Which text the home screen is showing: 'kural' | 'aathichudi' ----
  String get contentMode => _box.get('contentMode') as String? ?? 'kural';
  Future<void> setContentMode(String mode) => _box.put('contentMode', mode);

  // ---- Aathichudi daily progress (parallel to the kural track) ----
  int? get aathiLastNumber => _box.get('aathiLastNumber') as int?;
  String? get aathiLastDate => _box.get('aathiLastDate') as String?;

  /// What to do once every aathichudi has been shown: 'repeat' | 'random'.
  /// Null means the user hasn't chosen yet.
  String? get aathiEndMode => _box.get('aathiEndMode') as String?;
  Future<void> setAathiEndMode(String mode) => _box.put('aathiEndMode', mode);

  Future<void> saveAathiServed({
    required int number,
    required String date,
  }) async {
    await _box.put('aathiLastNumber', number);
    await _box.put('aathiLastDate', date);
  }
}
