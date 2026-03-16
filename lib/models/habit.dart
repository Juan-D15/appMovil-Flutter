class Habit {
  final String id;
  final String name;
  final String? note; //Nota opcional

  Habit({required this.id, required this.name, this.note});

  factory Habit.fromMap(String id, Map<String, dynamic> data) {
    return Habit(id: id, name: data['name'] ?? '', note: data['note']);
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'note': note};
  }
}
