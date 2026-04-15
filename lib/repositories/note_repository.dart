import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

class NoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'notes';

  Stream<List<Note>> getNotes(String userId) {
    // We'll keep the simple query and handle complex sorting (like pinning) in the app logic
    // to avoid requiring too many composite indexes from the user.
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Note.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addNote(Note note) async {
    await _firestore.collection(collection).add(note.toMap());
  }

  Future<void> updateNote(Note note) async {
    await _firestore.collection(collection).doc(note.id).update(note.toMap());
  }

  Future<void> deleteNote(String noteId) async {
    await _firestore.collection(collection).doc(noteId).delete();
  }
}
