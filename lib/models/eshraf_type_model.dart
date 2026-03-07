class EshrafType {
  final String id;
  final String name;
  final String type; // 'deduction' or 'addition'
  final int factor; // -1 or 1

  EshrafType({
    required this.id,
    required this.name,
    required this.type,
    required this.factor,
  });

  factory EshrafType.fromJson(Map<String, dynamic> json) {
    return EshrafType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      factor: json['factor'] ?? 0,
    );
  }

  bool get isDeduction => type == 'deduction';
  bool get isAddition => type == 'addition';
}