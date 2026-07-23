import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/transaction_provider.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final _currencyFormat = NumberFormat.compactCurrency(locale: "tr_TR", symbol: "₺");
  String _selectedPeriod = "daily";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<TransactionProvider>().fetchChartData(period: _selectedPeriod);
    });
  }

  void _changePeriod(String period) {
    setState(() => _selectedPeriod = period);
    context.read<TransactionProvider>().fetchChartData(period: period);
  }

  @override
  Widget build(BuildContext context) {
    final chartData = context.watch<TransactionProvider>().chartData;

    return Scaffold(
      appBar: AppBar(title: const Text("Alım-Satım Grafiği")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: "daily", label: Text("Günlük")),
                ButtonSegment(value: "weekly", label: Text("Haftalık")),
                ButtonSegment(value: "monthly", label: Text("Aylık")),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (newSelection) => _changePeriod(newSelection.first),
            ),
            const SizedBox(height: 24),
            _buildLegend(),
            const SizedBox(height: 16),
            Expanded(
              child: chartData.isEmpty
                  ? const Center(child: Text("Henüz gösterilecek veri yok."))
                  : _buildChart(chartData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(Colors.green, "Alış"),
        const SizedBox(width: 20),
        _legendDot(Colors.red, "Satış"),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  Widget _buildChart(List<ChartPoint> data) {
    final maxY = data
        .map((d) => d.buyTotal > d.sellTotal ? d.buyTotal : d.sellTotal)
        .fold<double>(0, (prev, el) => el > prev ? el : prev);

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 100 : maxY * 1.2,
        barGroups: List.generate(data.length, (index) {
          final point = data[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(toY: point.buyTotal, color: Colors.green, width: 8),
              BarChartRodData(toY: point.sellTotal, color: Colors.red, width: 8),
            ],
          );
        }),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                _currencyFormat.format(value),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[index].period.substring(5),
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
      ),
    );
  }
}