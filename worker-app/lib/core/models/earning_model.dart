class EarningModel {
  final String id;
  final String treeId;
  final String treeNumber;
  final double amount;
  final String type; // planting | maintenance | monthly
  final String status; // pending | paid
  final DateTime earnedAt;

  const EarningModel({
    required this.id,
    required this.treeId,
    required this.treeNumber,
    required this.amount,
    required this.type,
    required this.status,
    required this.earnedAt,
  });

  factory EarningModel.fromJson(Map<String, dynamic> j) => EarningModel(
        id: j['id'] ?? '',
        treeId: j['tree_id'] ?? '',
        treeNumber: j['tree_number'] ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
        type: j['type'] ?? 'planting',
        status: j['status'] ?? 'pending',
        earnedAt: DateTime.parse(
            j['earned_at'] ?? DateTime.now().toIso8601String()),
      );
}
