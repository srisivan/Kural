class Aathichudi {
  final int number;
  final String poem; // the single-line aphorism
  final String meaning; // word-by-word gloss
  final String paraphrase; // simple restatement
  final String translation; // English

  Aathichudi({
    required this.number,
    required this.poem,
    required this.meaning,
    required this.paraphrase,
    required this.translation,
  });

  factory Aathichudi.fromJson(Map<String, dynamic> json) {
    return Aathichudi(
      number: json['number'] as int,
      poem: json['poem'] ?? '',
      meaning: json['meaning'] ?? '',
      paraphrase: json['paraphrase'] ?? '',
      translation: json['translation'] ?? '',
    );
  }
}
