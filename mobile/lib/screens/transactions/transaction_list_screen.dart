import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _currencyFormat = NumberFormat.currency(locale: "tr_TR", symbol: "₺");
  final _dateFormat = DateFormat("dd.MM.yyyy HH:mm");

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<TransactionProvider>().fetchTransactions();
    });
  }

  void _showFilterSheet() {
    final txProvider = context.read<TransactionProvider>();
    final assetController = TextEditingController();
    TransactionType? selectedType;
    bool favoritesOnly = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Filtrele", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: assetController,
                    decoration: const InputDecoration(
                      labelText: "Varlık adı",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<TransactionType?>(
                    segments: const [
                      ButtonSegment(value: null, label: Text("Tümü")),
                      ButtonSegment(value: TransactionType.buy, label: Text("Alış")),
                      ButtonSegment(value: TransactionType.sell, label: Text("Satış")),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (newSelection) {
                      setModalState(() => selectedType = newSelection.first);
                    },
                  ),
                  SwitchListTile(
                    title: const Text("Sadece favoriler"),
                    value: favoritesOnly,
                    onChanged: (value) {
                      setModalState(() => favoritesOnly = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      txProvider.setFilters(
                        assetName: assetController.text.trim(),
                        type: selectedType,
                        favoritesOnly: favoritesOnly,
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text("Uygula"),
                  ),
                  TextButton(
                    onPressed: () {
                      txProvider.clearFilters();
                      Navigator.of(context).pop();
                    },
                    child: const Text("Filtreleri Temizle"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tüm İşlemler"),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: txProvider.hasActiveFilters ? Colors.indigo : null,
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: txProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : txProvider.transactions.isEmpty
              ? const Center(child: Text("İşlem bulunamadı."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: txProvider.transactions.length,
                  itemBuilder: (context, index) {
                    final tx = txProvider.transactions[index];
                    final isBuy = tx.transactionType == TransactionType.buy;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isBuy ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isBuy ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(tx.assetName),
                        subtitle: Text(
                          "${tx.quantity} adet • ${_currencyFormat.format(tx.pricePerUnit)}\n${_dateFormat.format(tx.transactionDate)}",
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                tx.isFavorite ? Icons.star : Icons.star_border,
                                color: tx.isFavorite ? Colors.amber : null,
                              ),
                              onPressed: () => txProvider.toggleFavorite(tx),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey),
                              onPressed: () => _confirmDelete(tx.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _confirmDelete(int transactionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("İşlemi Sil"),
        content: const Text("Bu işlemi silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Vazgeç"),
          ),
          TextButton(
            onPressed: () {
              context.read<TransactionProvider>().deleteTransaction(transactionId);
              Navigator.of(context).pop();
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}