import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:appmovilx/screens/habit_history_screen.dart';
import 'package:appmovilx/screens/progreso_semanal_screen.dart';
import '../services/habit_service.dart';
import '../models/habit.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis Hábitos',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF9F6FE),
        primaryColor: Colors.deepPurple,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          labelLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) return const HomeScreen();
          return LoginScreen();
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final habitService = HabitService();
  final habitController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    NotificationService.scheduleDailyReminder(
      hour: 20,
      minute: 0,
      message: 'No olvides marcar tus hábitos hoy',
    );
  }

  void _editHabit(
    String habitId,
    String currentName,
    String? currentNote,
  ) async {
    final nameController = TextEditingController(text: currentName);
    final noteCtrl = TextEditingController(text: currentNote ?? '');

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Editar hábito"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nuevo nombre"),
                ),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: "Nota"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Guardar"),
              ),
            ],
          ),
    );

    if (confirm == true && nameController.text.trim().isNotEmpty) {
      await habitService.updateHabitName(habitId, nameController.text.trim());
      await habitService.updateHabitNote(habitId, noteCtrl.text.trim());
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.deepPurple;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tus Hábitos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm),
            tooltip: 'Configurar recordatorio',
            onPressed: () async {
              final selectedTime = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 20, minute: 0),
              );

              if (selectedTime != null) {
                await NotificationService.scheduleDailyReminder(
                  hour: selectedTime.hour,
                  minute: selectedTime.minute,
                  message: 'No olvides marcar tus hábitos hoy',
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '⏰ Notificación programada a las ${selectedTime.format(context)}',
                    ),
                    backgroundColor: Colors.deepPurple,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
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
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                TextField(
                  controller: habitController,
                  decoration: InputDecoration(
                    hintText: "Nuevo hábito",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    hintText: "Nota o descripción",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    final name = habitController.text.trim();
                    final note = noteController.text.trim();
                    if (name.isNotEmpty) {
                      habitService.addHabit(name, note: note);
                      habitController.clear();
                      noteController.clear();
                    }
                  },
                  child: const Icon(Icons.add),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Habit>>(
              stream: habitService.getHabits(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final habits = snapshot.data!;
                return ListView.builder(
                  itemCount: habits.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    return FutureBuilder<List<dynamic>>(
                      future: Future.wait([
                        habitService.getCompletionCountThisWeek(
                          habits[index].id,
                        ),
                        habitService.getLastCompletionTime(habits[index].id),
                      ]),
                      builder: (context, snap) {
                        if (!snap.hasData) return const SizedBox.shrink();
                        final progressCount = snap.data![0] as int;
                        final lastTime = snap.data![1] as String?;
                        final progressValue = progressCount / 7.0;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text(
                              habits[index].name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (habits[index].note?.isNotEmpty ?? false)
                                  Text(
                                    habits[index].note!,
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: progressValue,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text("Progreso semanal: $progressCount / 7"),
                                if (lastTime != null)
                                  Text("Último completado: $lastTime"),
                              ],
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              direction: Axis.vertical,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blueAccent,
                                  ),
                                  onPressed:
                                      () => _editHabit(
                                        habits[index].id,
                                        habits[index].name,
                                        habits[index].note,
                                      ),
                                  tooltip: 'Editar hábito',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  onPressed: () async {
                                    await habitService.markHabitAsDoneToday(
                                      habits[index].id,
                                    );
                                    final completados = await habitService
                                        .getCompletionCountThisWeek(
                                          habits[index].id,
                                        );
                                    if (completados == 7) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '🎉 ¡Completaste este hábito 7/7 esta semana!',
                                          ),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.all(16),
                                        ),
                                      );
                                      await habitService
                                          .incrementSuccessfulWeeks(
                                            habits[index].id,
                                          );
                                    }
                                    setState(() {});
                                  },
                                  tooltip: 'Marcar como hecho hoy',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text(
                                              "Eliminar hábito",
                                            ),
                                            content: const Text(
                                              "¿Estás seguro de que quieres eliminar este hábito?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: const Text("Cancelar"),
                                              ),
                                              ElevatedButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                child: const Text("Eliminar"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                    );
                                    if (confirm == true) {
                                      habitService.deleteHabit(
                                        habits[index].id,
                                      );
                                    }
                                  },
                                  tooltip: 'Eliminar hábito',
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => HabitHistoryScreen(
                                        habitId: habits[index].id,
                                        habitName: habits[index].name,
                                      ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
