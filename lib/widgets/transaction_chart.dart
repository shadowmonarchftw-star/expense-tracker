import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart'; // Import
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/transaction.dart';

class TransactionChart extends StatefulWidget {
  final List<Transaction> transactions;
  const TransactionChart({super.key, required this.transactions});

  @override
  State<TransactionChart> createState() => _TransactionChartState();
}

class _TransactionChartState extends State<TransactionChart> {
  String _filter = 'W'; // Default to Week

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) return const SizedBox.shrink();

    final dataPoints = _processData();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      // decoration handled by parent or card theme
      child: Column(
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'D', label: Text('D')),
              ButtonSegment(value: 'W', label: Text('W')),
              ButtonSegment(value: 'M', label: Text('M')),
              ButtonSegment(value: 'Y', label: Text('Y')),
            ],
            selected: {_filter},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _filter = newSelection.first;
              });
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return const Color(0xFF00C4B4);
                  }
                  return null;
                },
              ),
              foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                   if (states.contains(MaterialState.selected)) {
                     return Colors.white;
                   }
                   return Theme.of(context).colorScheme.onSurface;
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.70,
            child: dataPoints.isEmpty 
              ? Center(child: Text("No data for this period", style: TextStyle(color: Theme.of(context).hintColor)))
              : LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _getInterval(dataPoints.length.toDouble()),
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < dataPoints.length) {
                             return Padding(
                               padding: const EdgeInsets.only(top: 8.0),
                               child: Text(
                                 dataPoints[value.toInt()].label,
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                               ),
                             );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (dataPoints.length - 1).toDouble(),
                  minY: 0,
                  // Add some padding to top
                  maxY: dataPoints.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataPoints.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.amount);
                      }).toList(),
                      isCurved: true,
                      color: const Color(0xFF00C4B4),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00C4B4).withOpacity(0.3),
                            const Color(0xFF00C4B4).withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final flSpot = barSpot;
                          return LineTooltipItem(
                            '${dataPoints[flSpot.x.toInt()].label}\n',
                            const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: NumberFormat.simpleCurrency().format(flSpot.y),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
          ),
        ],
      ),
    );
  }

  double _getInterval(double length) {
    if (length <= 5) return 1;
    if (length <= 10) return 2;
    return length / 5;
  }

  List<_ChartPoint> _processData() {
    final provider = Provider.of<AppProvider>(context, listen: false); // Listen false usually ok here if parent rebuilds
    // But parent Dashboard DOES rebuild on provider change, so this should trigger.
    
    final bool isNepali = provider.isNepaliDate;
    final now = DateTime.now();
    final nepaliNow = NepaliDateTime.now();
    
    List<Transaction> filtered = [];
    
    // Sort by date ascending
    final sorted = List<Transaction>.from(widget.transactions)..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (sorted.isEmpty) return [];

    Map<int, double> grouped = {};
    List<_ChartPoint> points = [];

    // Filter Logic
    if (_filter == 'D') {
      // D = Hourly buckets for Today
      if (isNepali) {
         filtered = sorted.where((t) {
           final nDt = NepaliDateTime.fromDateTime(t.timestamp);
           return nDt.year == nepaliNow.year && nDt.month == nepaliNow.month && nDt.day == nepaliNow.day;
         }).toList();
      } else {
         filtered = sorted.where((t) => t.timestamp.year == now.year && t.timestamp.month == now.month && t.timestamp.day == now.day).toList();
      }
      
      for (int i = 0; i <= 24; i+=4) { 
         grouped[i] = 0;
      }
      for (var t in filtered) {
         if (t.type == 'expense') {
            int hour = t.timestamp.hour;
            int bucket = (hour ~/ 4) * 4;
            grouped[bucket] = (grouped[bucket] ?? 0) + t.amount;
         }
      }
      grouped.forEach((k, v) {
        points.add(_ChartPoint("${k}h", v)); 
      });

    } else if (_filter == 'W') {
      // Last 7 days
      final start = now.subtract(const Duration(days: 6));
      filtered = sorted.where((t) => t.timestamp.isAfter(start.subtract(const Duration(seconds: 1)))).toList();
      
      for (int i = 0; i < 7; i++) {
        // Here we just want the day label
        final date = start.add(Duration(days: i));
        grouped[date.day] = 0; // Key by day ID is risky if across month, but loop below handles it safely?
        // Note: Grouping by 'day number' fails if week crosses month boundary (e.g. 30, 31, 1, 2).
        // Better to use index 0..6
      }
      
      // Better approach for W: Map index 0-6
      Map<int, double> weekGrouped = {};
      for(int i=0; i<7; i++) weekGrouped[i] = 0;

      for (var t in filtered) {
        if (t.type == 'expense') {
           final diff = t.timestamp.difference(start).inDays;
           if (diff >= 0 && diff < 7) {
             weekGrouped[diff] = (weekGrouped[diff] ?? 0) + t.amount;
           }
        }
      }

      for (int i = 0; i < 7; i++) {
        final date = start.add(Duration(days: i));
        String label;
        if (isNepali) {
          label = NepaliDateFormat.E().format(NepaliDateTime.fromDateTime(date));
        } else {
          label = DateFormat.E().format(date);
        }
        points.add(_ChartPoint(label, weekGrouped[i] ?? 0));
      }

    } else if (_filter == 'M') {
      // This Month, daily
      if (isNepali) {
        filtered = sorted.where((t) {
           final nDt = NepaliDateTime.fromDateTime(t.timestamp);
           return nDt.year == nepaliNow.year && nDt.month == nepaliNow.month;
        }).toList();

        for (var t in filtered) {
           if (t.type == 'expense') {
             final nDt = NepaliDateTime.fromDateTime(t.timestamp);
             grouped[nDt.day] = (grouped[nDt.day] ?? 0) + t.amount;
           }
        }
        final daysInMonth = nepaliNow.totalDays; // valid? Check extension
        // nepali_utils might not have totalDays on instance directly, let's check or assume 32 max
        // Actually NepaliDateTime(year, month + 1, 0).day work? 
        // Let's safe bet: iterate 1 to 32? No that's ugly.
        // Let's just use what we have or max 32.
        for (int i = 1; i <= 32; i++) {
           // Basic cap check?
           if (i > 32) break; 
           // If we don't know days in month exactly without lookup, this loop might show empty days 31/32. 
           // Acceptable for V1.
           points.add(_ChartPoint(i.toString(), grouped[i] ?? 0));
        }

      } else {
        final start = DateTime(now.year, now.month, 1);
        filtered = sorted.where((t) => t.timestamp.isAfter(start.subtract(const Duration(seconds: 1))) && t.timestamp.month == now.month).toList();
        
        for (var t in filtered) {
           if (t.type == 'expense') {
             grouped[t.timestamp.day] = (grouped[t.timestamp.day] ?? 0) + t.amount;
           }
        }
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        for (int i = 1; i <= daysInMonth; i++) {
          points.add(_ChartPoint(i.toString(), grouped[i] ?? 0));
        }
      }

    } else if (_filter == 'Y') {
      // This Year, monthly
      if (isNepali) {
         filtered = sorted.where((t) => NepaliDateTime.fromDateTime(t.timestamp).year == nepaliNow.year).toList();
         for (int i = 1; i <= 12; i++) grouped[i] = 0;
         
         for (var t in filtered) {
           if (t.type == 'expense') {
             final nDt = NepaliDateTime.fromDateTime(t.timestamp);
             grouped[nDt.month] = (grouped[nDt.month] ?? 0) + t.amount;
           }
         }
         for (int i = 1; i <= 12; i++) {
           // Helper to get month name
           final dummy = NepaliDateTime(nepaliNow.year, i, 1);
           points.add(_ChartPoint(NepaliDateFormat.MMM().format(dummy), grouped[i]!));
         }

      } else {
         filtered = sorted.where((t) => t.timestamp.year == now.year).toList();
         
         for (int i = 1; i <= 12; i++) {
           grouped[i] = 0;
         }
         for (var t in filtered) {
           if (t.type == 'expense') {
              grouped[t.timestamp.month] = (grouped[t.timestamp.month] ?? 0) + t.amount;
           }
         }
         for (int i = 1; i <= 12; i++) {
           points.add(_ChartPoint(DateFormat.MMM().format(DateTime(now.year, i)), grouped[i]!));
         }
      }
    }

    return points;
  }
}

class _ChartPoint {
  final String label;
  final double amount;
  _ChartPoint(this.label, this.amount);
}
