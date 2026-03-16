import 'package:appmovilx/screens/progreso_semanal_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/habit_service.dart';

class HabitHistoryScreen extends StatefulWidget {
  final String habitId;
  final String habitName;

  const HabitHistoryScreen({
    super.key,
    required this.habitId,
    required this.habitName,
  });

  @override
  State<HabitHistoryScreen> createState() => _HabitHistoryScreenState();
}

class _HabitHistoryScreenState extends State<HabitHistoryScreen> {
  final HabitService _habitService = HabitService();
  Set<DateTime> _completedDates = {};

  @override
  void initState() {
    super.initState();
    _loadCompletions();
  }

  void _loadCompletions() async {
    await _habitService.resetHabitIfNewWeek(widget.habitId);
    final dates = await _habitService.getCompletionDates(widget.habitId);
    setState(() {
      _completedDates = dates;
    });
  }

  bool _isCompleted(DateTime day) {
    return _completedDates.any(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.deepPurple;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Tus Hábitos', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Ver resumen semanal',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProgresoSemanalScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF9F6FE),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2026, 12, 31),
          focusedDay: DateTime.now(),
          calendarStyle: CalendarStyle(
            isTodayHighlighted: true,
            todayDecoration: BoxDecoration(
              color: primaryColor.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
            weekendTextStyle: const TextStyle(color: Colors.grey),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) async {
            final isDone = _isCompleted(selectedDay);

            if (isDone) {
              final completedAt = await _habitService.getCompletionTimestamp(
                widget.habitId,
                selectedDay,
              );

              final formattedTime =
                  completedAt != null
                      ? '${completedAt.hour.toString().padLeft(2, '0')}:${completedAt.minute.toString().padLeft(2, '0')}'
                      : 'sin hora registrada';

              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text("¡Buen trabajo!"),
                      content: Text(
                        "Este hábito fue completado el ${selectedDay.day}/${selectedDay.month}/${selectedDay.year} a las $formattedTime.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cerrar"),
                        ),
                      ],
                    ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No se completó el hábito en esta fecha."),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, _) {
              final isDone = _isCompleted(day);
              return Container(
                decoration: BoxDecoration(
                  color: isDone ? Colors.green[400] : null,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isDone ? Colors.white : Colors.black,
                    fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
