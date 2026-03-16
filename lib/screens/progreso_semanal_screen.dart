import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/habit_service.dart';

class ProgresoSemanalScreen extends StatefulWidget {
  const ProgresoSemanalScreen({super.key});

  @override
  State<ProgresoSemanalScreen> createState() => _ProgresoSemanalScreenState();
}

class _ProgresoSemanalScreenState extends State<ProgresoSemanalScreen> {
  final HabitService _habitService = HabitService();
  Map<int, int> _conteoPorDia = {}; // 1: lunes, ..., 7: domingo

  @override
  void initState() {
    super.initState();
    _cargarProgresoSemanal();
  }

  void _cargarProgresoSemanal() async {
    final data = await _habitService.getWeeklyCompletionSummary();
    setState(() {
      _conteoPorDia = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.deepPurple;
    final totalHabitos = _conteoPorDia.values.fold(0, (a, b) => a + b);
    final dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Resumen semanal",
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: const Color(0xFFF9F6FE),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta semana completaste $totalHabitos hábitos.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (_conteoPorDia.values.isNotEmpty)
                          ? _conteoPorDia.values
                                  .reduce((a, b) => a > b ? a : b)
                                  .toDouble() +
                              1
                          : 5,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipBorder: BorderSide(color: primaryColor),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final dayName = [
                          'Lunes',
                          'Martes',
                          'Miércoles',
                          'Jueves',
                          'Viernes',
                          'Sábado',
                          'Domingo',
                        ];
                        return BarTooltipItem(
                          '${dayName[group.x]}\n${rod.toY.toInt()} hábitos',
                          TextStyle(
                            backgroundColor: primaryColor.shade100,
                            color: primaryColor.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              dias[value.toInt()],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, _) => Text('${value.toInt()}'),
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    final count = _conteoPorDia[index + 1] ?? 0;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: [Colors.deepPurple, Colors.purpleAccent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                swapAnimationDuration: const Duration(milliseconds: 700),
                swapAnimationCurve: Curves.easeOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
