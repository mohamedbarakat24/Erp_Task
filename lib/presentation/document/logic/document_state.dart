import '../models/document.dart';

abstract class DocumentState {}

class DocumentInitial extends DocumentState {}

class DocumentLoading extends DocumentState {}

class DocumentLoaded extends DocumentState {
  final List<Document> documents;
  DocumentLoaded(this.documents);
}

class DocumentError extends DocumentState {
  final String message;
  DocumentError(this.message);
}
