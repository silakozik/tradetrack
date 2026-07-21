enum TransactionType { buy, sell }

TransactionType transactionTypeFromString(String value) {
  return value == "buy" ? TransactionType.buy : TransactionType.sell;
}

String transactionTypeToString(TransactionType type) {
  return type == TransactionType.buy ? "buy" : "sell";
}

class AppTransaction {
  final int id;
  final int userId;
  final String assetName;
  final TransactionType transactionType;
  final double quantity;
  final double pricePerUnit;
  final double totalAmount;
  final DateTime transactionDate;
  final bool isFavorite;

  AppTransaction({
    required this.id,
    required this.userId,
    required this.assetName,
    required this.transactionType,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalAmount,
    required this.transactionDate,
    required this.isFavorite,
  });

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    return AppTransaction(
      id: json["id"],
      userId: json["user_id"],
      assetName: json["asset_name"],
      transactionType: transactionTypeFromString(json["transaction_type"]),
      quantity: (json["quantity"] as num).toDouble(),
      pricePerUnit: (json["price_per_unit"] as num).toDouble(),
      totalAmount: (json["total_amount"] as num).toDouble(),
      transactionDate: DateTime.parse(json["transaction_date"]),
      isFavorite: json["is_favorite"] == 1,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      "asset_name": assetName,
      "transaction_type": transactionTypeToString(transactionType),
      "quantity": quantity,
      "price_per_unit": pricePerUnit,
    };
  }
}