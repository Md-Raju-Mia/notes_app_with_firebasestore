import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String userId;
  final int color;
  final bool isPinned;
  final String category;

  Note({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.userId,
    this.color = 0xFFFFFFFF,
    this.isPinned = false,
    this.category = 'General',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      'color': color,
      'isPinned': isPinned,
      'category': category,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map, String documentId) {
    return Note(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
      color: map['color'] ?? 0xFFFFFFFF,
      isPinned: map['isPinned'] ?? false,
      category: map['category'] ?? 'General',
    );
  }

  Note copyWith({
    String? title,
    String? description,
    DateTime? timestamp,
    int? color,
    bool? isPinned,
    String? category,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      userId: userId,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
    );
  }
}
