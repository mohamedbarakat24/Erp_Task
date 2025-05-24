import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/document.dart';
import 'document_event.dart';
import 'document_state.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final List<Document> _documents = [];

  DocumentBloc() : super(DocumentInitial()) {
    on<LoadDocuments>((event, emit) {
      emit(DocumentLoading());
      emit(DocumentLoaded(List.from(_documents)));
    });

    on<AddDocument>((event, emit) {
      _documents.add(event.document);
      emit(DocumentLoaded(List.from(_documents)));
    });

    on<UpdateDocument>((event, emit) {
      int index = _documents.indexWhere((d) => d.id == event.document.id);
      if (index != -1) {
        _documents[index] = event.document;
        emit(DocumentLoaded(List.from(_documents)));
      } else {
        emit(DocumentError('Document not found'));
      }
    });

    on<DeleteDocument>((event, emit) {
      _documents.removeWhere((d) => d.id == event.documentId);
      emit(DocumentLoaded(List.from(_documents)));
    });
  }
}
