
import 'dart:convert';

class BeerEntry {
  final DateTime date;
  final double amount; 

  BeerEntry({required this.date, required this.amount});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'amount': amount,
      };

  static BeerEntry fromJson(Map<String, dynamic> json) {
    return BeerEntry(
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  static List<BeerEntry> listFromJson(String jsonStr) {
    final List decoded = json.decode(jsonStr);
    return decoded.map((e) => BeerEntry.fromJson(e)).toList();
  }

  static String listToJson(List<BeerEntry> entries) {
    return json.encode(entries.map((e) => e.toJson()).toList());
  }
}
