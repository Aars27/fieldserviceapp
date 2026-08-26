import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../../../jobs/domain/entities/attachment.dart';
import '../providers/job_detail_provider.dart';

class AttachmentItem extends ConsumerStatefulWidget {
  final Attachment attachment;
  final String jobId;

  const AttachmentItem({super.key, required this.attachment, required this.jobId});

  @override
  ConsumerState<AttachmentItem> createState() => _AttachmentItemState();
}

class _AttachmentItemState extends ConsumerState<AttachmentItem> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final kb = (widget.attachment.sizeBytes / 1024).toStringAsFixed(1);

    return ListTile(
      leading: Icon(_mimeIcon(widget.attachment.mimeType), color: cs.primary),
      title: Text(widget.attachment.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('$kb KB'),
      trailing: Icon(Icons.open_in_new, size: 18, color: cs.outline),
      onTap: () {
        // TODO: open with url_launcher once that dep is added
      },
    );
  }

  IconData _mimeIcon(String mime) {
    if (mime.startsWith('image/')) return Icons.image_outlined;
    if (mime == 'application/pdf') return Icons.picture_as_pdf_outlined;
    return Icons.attach_file;
  }
}

/// The "Add attachment" button with upload progress + retry.
class AddAttachmentButton extends ConsumerStatefulWidget {
  final String jobId;

  const AddAttachmentButton({super.key, required this.jobId});

  @override
  ConsumerState<AddAttachmentButton> createState() => _AddAttachmentButtonState();
}

class _AddAttachmentButtonState extends ConsumerState<AddAttachmentButton> {
  double? _progress;
  bool _failed = false;
  XFile? _lastFile;

  @override
  Widget build(BuildContext context) {
    if (_progress != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: LinearProgressIndicator(value: _progress),
      );
    }

    return Row(
      children: [
        FilledButton.tonal(
          onPressed: _pick,
          child: const Text('Add attachment'),
        ),
        if (_failed) ...[
          const SizedBox(width: 8),
          TextButton(onPressed: _retry, child: const Text('Retry')),
        ],
      ],
    );
  }

  Future<void> _pick() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file == null) return;
    _lastFile = file;
    await _upload(file);
  }

  Future<void> _retry() async {
    if (_lastFile == null) return;
    setState(() => _failed = false);
    await _upload(_lastFile!);
  }

  Future<void> _upload(XFile xfile) async {
    setState(() {
      _progress = 0;
      _failed = false;
    });

    File file = File(xfile.path);

    // Compress before upload if it's an image
    if (xfile.mimeType?.startsWith('image/') ?? xfile.path.endsWith('.jpg') || xfile.path.endsWith('.png')) {
      final dir = await getTemporaryDirectory();
      final outPath = '${dir.path}/compressed_${xfile.name}';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        xfile.path,
        outPath,
        quality: 75,
      );
      if (compressed != null) file = File(compressed.path);
    }

    final error = await ref.read(jobDetailProvider(widget.jobId).notifier).uploadAttachment(
          file,
          (progress) => setState(() => _progress = progress),
        );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _progress = null;
        _failed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
    } else {
      setState(() => _progress = null);
    }
  }
}
