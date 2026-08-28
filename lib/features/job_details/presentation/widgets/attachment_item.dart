import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../jobs/domain/entities/attachment.dart';
import '../providers/job_detail_provider.dart';

class AttachmentItem extends ConsumerWidget {
  final Attachment attachment;
  final String jobId;

  const AttachmentItem({super.key, required this.attachment, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardTheme.color ??
        (isDark ? const Color(0xFF1E293B) : Colors.white);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final kb = (attachment.sizeBytes / 1024).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_mimeIcon(attachment.mimeType), color: cs.primary, size: 22),
          ),
          title: Text(
            attachment.filename,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            '$kb KB · ${attachment.mimeType.split('/').last.toUpperCase()}',
            style: TextStyle(color: cs.outline, fontSize: 12),
          ),
          trailing: Icon(Icons.open_in_new_rounded, size: 18, color: cs.outline),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening ${attachment.filename}…'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _mimeIcon(String mime) {
    if (mime.startsWith('image/')) return Icons.image_outlined;
    if (mime == 'application/pdf') return Icons.picture_as_pdf_outlined;
    return Icons.insert_drive_file_outlined;
  }
}

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
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Uploading attachment…',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${((_progress ?? 0) * 100).toInt()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: _progress, minHeight: 6),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
            label: const Text('Add Photo / Attachment'),
            onPressed: _pick,
          ),
        ),
        if (_failed) ...[
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _retry,
            child: const Text('Retry'),
          ),
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
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      setState(() => _progress = null);
    }
  }
}
