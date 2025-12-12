class Beer {
  final String id;
  final String name;
  final String brewery;
  final String region;
  final double? abv;
  final String? style;
  final String? notes;

  Beer({
    required this.id,
    required this.name,
    required this.brewery,
    required this.region,
    this.abv,
    this.style,
    this.notes,
  });

  factory Beer.fromFirestore(String id, Map<String, dynamic> data) {
    return Beer(
      id: id,
      name: data['name'] ?? '',
      brewery: data['brewery'] ?? '',
      region: data['region'] ?? '',
      abv: (data['abv'] as num?)?.toDouble(),
      style: data['style'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brewery': brewery,
      'region': region,
      'abv': abv,
      'style': style,
      'notes': notes,
    };
  }
}

