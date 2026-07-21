import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _assetNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  TransactionType _selectedType = TransactionType.buy;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _assetNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final txProvider = context.read<TransactionProvider>();
    final success = await txProvider.addTransaction(
      assetName: _assetNameController.text.trim(),
      type: _selectedType,
      quantity: double.parse(_quantityController.text),
      pricePerUnit: double.parse(_priceController.text),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(txProvider.errorMessage ?? "İşlem eklenemedi.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni İşlem")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.buy,
                    label: Text("Alış"),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: TransactionType.sell,
                    label: Text("Satış"),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (newSelection) {
                  setState(() => _selectedType = newSelection.first);
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _assetNameController,
                decoration: const InputDecoration(
                  labelText: "Varlık Adı (örn: Bitcoin, Altın)",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "Varlık adı gerekli";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Miktar",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Miktar gerekli";
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) return "Geçerli bir miktar girin";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Birim Fiyat (₺)",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Fiyat gerekli";
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) return "Geçerli bir fiyat girin";
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Kaydet"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}