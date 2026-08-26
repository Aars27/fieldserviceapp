import 'package:equatable/equatable.dart';

class Attachment extends Equatable {
  final String id;
  final String filename;
  final String url;
  final String mimeType;
  final int sizeBytes;

  const Attachment({
    required this.id,
    required this.filename,
    required this.url,
    required this.mimeType,
    required this.sizeBytes,
  });

  @override
  List<Object?> get props => [id, url];
}
