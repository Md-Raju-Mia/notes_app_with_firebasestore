import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../repositories/note_repository.dart';

class NoteViewModel extends ChangeNotifier {
  final NoteRepository _noteRepository = NoteRepository();
  bool _isDescending = true;
  String _selectedCategory = 'All';

  bool get isDescending => _isDescending;
  String get selectedCategory => _selectedCategory;

  final List<String> categories = ['All', 'General', 'Work', 'Personal', 'Ideas', 'Important'];

  void toggleSortOrder() {
    _isDescending = !_isDescending;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Stream<List<Note>> getNotesStream(String userId) {
    // Note: The Firestore query in the repository might need to be adjusted for pinning
    // or we handle sorting/pinning logic here or in the UI.
    return _noteRepository.getNotes(userId);
  }

  Future<void> addNote(Note note) async {
    try {
      await _noteRepository.addNote(note);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      await _noteRepository.updateNote(note);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _noteRepository.deleteNote(noteId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> togglePin(Note note) async {
    final updatedNote = note.copyWith(isPinned: !note.isPinned);
    await updateNote(updatedNote);
  }
}
