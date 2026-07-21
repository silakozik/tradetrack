import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../transactions/transaction_list_screen.dart';
import '../transactions/add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _currencyFormat = NumberFormat.currency(locale: "tr_TR", symbol: "₺");

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<TransactionProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("TradeTrack"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => txProvider.loadAll(),
        child: txProvider.isLoading && txProvider.portfolioAssets.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(txProvider),
                  const SizedBox(height: 20),
                  Text(
                    "Varlıklarım",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (txProvider.portfolioAssets.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text("Henüz işlem eklenmemiş.")),
                    )
                  else
                    ...txProvider.portfolioAssets.map(
                      (asset) => _buildAssetTile(asset),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("İşlem Ekle"),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TransactionListScreen()),
                );
              },
              icon: const Icon(Icons.list),
              label: const Text("Tüm İşlemler"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(TransactionProvider txProvider) {
    final isProfit = txProvider.totalProfitLoss >= 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Toplam Portföy Değeri",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _currencyFormat.format(txProvider.totalPortfolioValue),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  isProfit ? Icons.trending_up : Icons.trending_down,
                  color: isProfit ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  "Gerçekleşen K/Z: ${_currencyFormat.format(txProvider.totalProfitLoss)}",
                  style: TextStyle(
                    color: isProfit ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetTile(PortfolioAsset asset) {
    final isProfit = asset.realizedProfitLoss >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(asset.assetName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          "Miktar: ${asset.remainingQuantity} • Ort. Alış: ${_currencyFormat.format(asset.avgBuyPrice)}",
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _currencyFormat.format(asset.currentHoldingValue),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              _currencyFormat.format(asset.realizedProfitLoss),
              style: TextStyle(
                color: isProfit ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}