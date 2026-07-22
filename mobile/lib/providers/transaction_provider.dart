import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/transaction.dart';

class PortfolioAsset {
  final String assetName;
  final double remainingQuantity;
  final double avgBuyPrice;
  final double currentHoldingValue;
  final double realizedProfitLoss;

  PortfolioAsset({
    required this.assetName,
    required this.remainingQuantity,
    required this.avgBuyPrice,
    required this.currentHoldingValue,
    required this.realizedProfitLoss,
  });

  factory PortfolioAsset.fromJson(Map<String, dynamic> json) {
    return PortfolioAsset(
      assetName: json["asset_name"],
      remainingQuantity: (json["remaining_quantity"] as num).toDouble(),
      avgBuyPrice: (json["avg_buy_price"] as num).toDouble(),
      currentHoldingValue: (json["current_holding_value"] as num).toDouble(),
      realizedProfitLoss: (json["realized_profit_loss"] as num).toDouble(),
    );
  }
}

class ChartPoint {
  final String period;
  final double buyTotal;
  final double sellTotal;

  ChartPoint({
    required this.period,
    required this.buyTotal,
    required this.sellTotal,
  });

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      period: json["period"],
      buyTotal: (json["buy_total"] as num).toDouble(),
      sellTotal: (json["sell_total"] as num).toDouble(),
    );
  }
}

class TransactionProvider with ChangeNotifier {
  List<AppTransaction> _transactions = [];
  List<PortfolioAsset> _portfolioAssets = [];
  double _totalPortfolioValue = 0;
  double _totalProfitLoss = 0;

  List<ChartPoint> _chartData = [];
  String _chartPeriod = "daily";

  bool _isLoading = false;
  String? _errorMessage;

  // Aktif filtreler
  String? _filterAssetName;
  TransactionType? _filterType;
  bool _filterFavoritesOnly = false;

  List<AppTransaction> get transactions => _transactions;
  List<PortfolioAsset> get portfolioAssets => _portfolioAssets;
  double get totalPortfolioValue => _totalPortfolioValue;
  double get totalProfitLoss => _totalProfitLoss;
  List<ChartPoint> get chartData => _chartData;
  String get chartPeriod => _chartPeriod;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasActiveFilters =>
      _filterAssetName != null || _filterType != null || _filterFavoritesOnly;

  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (_filterAssetName != null && _filterAssetName!.isNotEmpty) {
        queryParams["asset_name"] = _filterAssetName!;
      }
      if (_filterType != null) {
        queryParams["transaction_type"] = transactionTypeToString(_filterType!);
      }
      if (_filterFavoritesOnly) {
        queryParams["favorites_only"] = "true";
      }

      final uri = Uri.parse(ApiConstants.transactions).replace(queryParameters: queryParams);
      final result = await ApiClient.get(uri.toString());

      _transactions = (result as List)
          .map((json) => AppTransaction.fromJson(json))
          .toList();
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPortfolioSummary() async {
    try {
      final result = await ApiClient.get(ApiConstants.portfolioSummary);
      _portfolioAssets = (result["assets"] as List)
          .map((json) => PortfolioAsset.fromJson(json))
          .toList();
      _totalPortfolioValue = (result["total_portfolio_value"] as num).toDouble();
      _totalProfitLoss = (result["total_realized_profit_loss"] as num).toDouble();
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> fetchChartData({String period = "daily"}) async {
    _chartPeriod = period;
    try {
      final uri = Uri.parse(ApiConstants.chartSummary)
          .replace(queryParameters: {"period": period});
      final result = await ApiClient.get(uri.toString());

      _chartData = (result["data"] as List)
          .map((json) => ChartPoint.fromJson(json))
          .toList();
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    await Future.wait([fetchTransactions(), fetchPortfolioSummary()]);
  }

  Future<bool> addTransaction({
    required String assetName,
    required TransactionType type,
    required double quantity,
    required double pricePerUnit,
  }) async {
    try {
      await ApiClient.post(ApiConstants.transactions, {
        "asset_name": assetName,
        "transaction_type": transactionTypeToString(type),
        "quantity": quantity,
        "price_per_unit": pricePerUnit,
      });
      await loadAll();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleFavorite(AppTransaction transaction) async {
    try {
      await ApiClient.put(
        "${ApiConstants.transactions}${transaction.id}",
        {"is_favorite": !transaction.isFavorite},
      );
      await fetchTransactions();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      await ApiClient.delete("${ApiConstants.transactions}$id");
      await loadAll();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  void setFilters({
    String? assetName,
    TransactionType? type,
    bool? favoritesOnly,
  }) {
    _filterAssetName = assetName;
    _filterType = type;
    _filterFavoritesOnly = favoritesOnly ?? false;
    fetchTransactions();
  }

  void clearFilters() {
    _filterAssetName = null;
    _filterType = null;
    _filterFavoritesOnly = false;
    fetchTransactions();
  }
}