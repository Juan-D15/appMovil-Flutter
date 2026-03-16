import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit.dart';

class HabitService {
  final _firestore = FirebaseFirestore.instance;
  final _userId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> addHabit(String name, {String? note}) async {
    await _firestore.collection('users').doc(_userId).collection('habits').add({
      'name': name,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Habit>> getHabits() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('habits')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Habit.fromMap(doc.id, doc.data()))
                  .toList(),
        );
  }

  Future<void> deleteHabit(String habitId) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('habits')
        .doc(habitId)
        .delete();
  }

  Future<void> markHabitAsDoneToday(String habitId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final formattedDate =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('habits')
        .doc(habitId)
        .collection('completions')
        .doc(formattedDate)
        .set({'done': true, 'timestamp': FieldValue.serverTimestamp()});
  }

  Future<int> getCompletionCountThisWeek(String habitId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Lunes

    int count = 0;
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final formattedDate =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final doc =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('habits')
              .doc(habitId)
              .collection('completions')
              .doc(formattedDate)
              .get();

      if (doc.exists) count++;
    }

    return count;
  }

  Future<Set<DateTime>> getCompletionDates(String habitId) async {
    final snapshot =
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('habits')
            .doc(habitId)
            .collection('completions')
            .get();

    return snapshot.docs.map((doc) {
      if (doc.data().containsKey('timestamp')) {
        final timestamp = doc['timestamp'] as Timestamp;
        return timestamp.toDate().toLocal();
      } else {
        // si no tiene timestamp, usar el ID como fecha de respaldo
        final parts = doc.id.split('-');
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        ).toLocal();
      }
    }).toSet();
  }

  Future<Map<int, int>> getWeeklyCompletionSummary() async {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1)); // lunes

    final habitsSnapshot =
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('habits')
            .get();

    Map<int, int> summary = {for (var i = 1; i <= 7; i++) i: 0};

    for (var habitDoc in habitsSnapshot.docs) {
      final completionsSnapshot =
          await habitDoc.reference.collection('completions').get();

      for (var doc in completionsSnapshot.docs) {
        final parts = doc.id.split('-');
        if (parts.length == 3) {
          final date =
              DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              ).toLocal();

          final dayOnly = DateTime(date.year, date.month, date.day);
          final weekStart = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          );

          if (dayOnly.isAtSameMomentAs(weekStart) ||
              dayOnly.isAfter(weekStart)) {
            final weekday = dayOnly.weekday;
            summary[weekday] = summary[weekday]! + 1;
          }
        }
      }
    }

    return summary;
  }

  Future<void> incrementSuccessfulWeeks(String habitId) async {
    final doc = _firestore
        .collection('users')
        .doc(_userId)
        .collection('habits')
        .doc(habitId);
    await doc.update({'successfulWeeks': FieldValue.increment(1)});
  }

  Future<void> resetHabitIfNewWeek(String habitId) async {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1)); // lunes

    final completionsRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('habits')
        .doc(habitId)
        .collection('completions');

    final snapshot = await completionsRef.get();

    for (var doc in snapshot.docs) {
      final parts = doc.id.split('-');
      if (parts.length == 3) {
        final date =
            DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            ).toLocal();

        final dateOnly = DateTime(date.year, date.month, date.day);
        final weekStart = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );

        if (dateOnly.isBefore(weekStart)) {
          await completionsRef.doc(doc.id).delete();
        }
      }
    }
  }

  Future<void> updateHabitName(String habitId, String newName) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('habits')
        .doc(habitId)
        .update({'name': newName});
  }

  Future<void> updateHabitNote(String habitId, String note) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('habits')
        .doc(habitId)
        .update({'note': note});
  }

  Future<DateTime?> getCompletionTimestamp(String habitId, DateTime day) async {
    final key =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    final doc =
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('habits')
            .doc(habitId)
            .collection('completions')
            .doc(key)
            .get();

    if (doc.exists && doc.data()!.containsKey('timestamp')) {
      final timestamp = doc['timestamp'] as Timestamp;
      return timestamp.toDate().toLocal();
    }

    return null;
  }

  Future<String?> getLastCompletionTime(String habitId) async {
    final completionsRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('habits')
        .doc(habitId)
        .collection('completions');

    final snapshot =
        await completionsRef
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final timestamp = snapshot.docs.first['timestamp'] as Timestamp;
      final date = timestamp.toDate().toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    return null;
  }
}
