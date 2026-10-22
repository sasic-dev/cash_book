import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/services/attachment_service.dart';

/// Interactive UI component for attaching receipts, bills, and documents.
/// Adheres strictly to the app's zero-border-radius design aesthetic,
/// supports light and dark themes, full-screen zoom previews, and read-only mode.
class AttachmentPickerBox extends StatefulWidget {
  final String? attachmentPath;
  final ValueChanged<String?> onAttachmentChanged;
  final bool isReadOnly;
  final IAttachmentService? attachmentService;

  const AttachmentPickerBox({
    super.key,
    required this.attachmentPath,
    required this.onAttachmentChanged,
    this.isReadOnly = false,
    this.attachmentService,
  });

  @override
  State<AttachmentPickerBox> createState() => _AttachmentPickerBoxState();
}

class _AttachmentPickerBoxState extends State<AttachmentPickerBox> {
  late final IAttachmentService _service;
  String? _fileSizeText;

  @override
  void initState() {
    super.initState();
    _service = widget.attachmentService ?? AttachmentService();
    _loadFileMetadata();
  }

  @override
  void didUpdateWidget(covariant AttachmentPickerBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachmentPath != widget.attachmentPath) {
      _loadFileMetadata();
    }
  }

  Future<void> _loadFileMetadata() async {
    final path = widget.attachmentPath;
    if (path == null || path.isEmpty) {
      if (mounted) setState(() => _fileSizeText = null);
      return;
    }
    final bytes = await _service.getFileSizeBytes(path);
    if (mounted) {
      setState(() {
        _fileSizeText = _service.formatFileSize(bytes);
      });
    }
  }

  bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.bmp');
  }

  bool _isPdfPath(String path) {
    return path.toLowerCase().endsWith('.pdf');
  }

  Future<void> _captureCamera() async {
    final path = await _service.captureFromCamera();
    if (path != null && mounted) {
      widget.onAttachmentChanged(path);
    }
  }

  Future<void> _pickGallery() async {
    final path = await _service.pickFromGallery();
    if (path != null && mounted) {
      widget.onAttachmentChanged(path);
    }
  }

  Future<void> _pickDocument() async {
    final path = await _service.pickDocument();
    if (path != null && mounted) {
      widget.onAttachmentChanged(path);
    }
  }

  void _showChangeOptions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Change Attachment',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.blue),
                title: const Text('Take Photo from Camera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _captureCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.green),
                title: const Text('Choose Image from Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_rounded, color: Colors.orange),
                title: const Text('Choose Document (PDF / Doc)'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickDocument();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewFullScreen() {
    final path = widget.attachmentPath;
    if (path == null || path.isEmpty) return;

    final isImg = _isImagePath(path);

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Center(
                child: isImg
                    ? InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: File(path).existsSync()
                            ? Image.file(File(path))
                            : const Icon(
                                Icons.broken_image_rounded,
                                color: Colors.white,
                                size: 64,
                              ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(24),
                        color: const Color(0xFF1E293B),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isPdfPath(path)
                                  ? Icons.picture_as_pdf_rounded
                                  : Icons.description_rounded,
                              size: 64,
                              color: _isPdfPath(path)
                                  ? Colors.redAccent
                                  : Colors.orangeAccent,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _service.getFileName(path),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_fileSizeText != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _fileSizeText!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final path = widget.attachmentPath;
    final hasAttachment = path != null && path.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Receipt / Document',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              child: const Text(
                'Optional',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (!hasAttachment) ...[
          // Empty state: show picker buttons
          if (widget.isReadOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.attachment_rounded, size: 20, color: Colors.grey),
                  SizedBox(width: 10),
                  Text(
                    'No receipt or document attached',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Upload camera bill, image, or doc',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Camera Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _captureCamera,
                          icon: const Icon(Icons.camera_alt_rounded, size: 17),
                          label: const Text('Camera'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Gallery Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickGallery,
                          icon: const Icon(Icons.photo_library_rounded, size: 17),
                          label: const Text('Photo'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Document Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDocument,
                          icon: const Icon(Icons.description_rounded, size: 17),
                          label: const Text('Doc/PDF'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ] else ...[
          // Attached preview state
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Thumbnail or Doc Icon
                GestureDetector(
                  onTap: _viewFullScreen,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    alignment: Alignment.center,
                    child: _isImagePath(path) && File(path).existsSync()
                        ? Image.file(
                            File(path),
                            fit: BoxFit.cover,
                            width: 58,
                            height: 58,
                          )
                        : Icon(
                            _isPdfPath(path)
                                ? Icons.picture_as_pdf_rounded
                                : Icons.description_rounded,
                            color: _isPdfPath(path)
                                ? Colors.redAccent
                                : Colors.orangeAccent,
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // File Details
                Expanded(
                  child: InkWell(
                    onTap: _viewFullScreen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: _isImagePath(path)
                                    ? Colors.blue.withValues(alpha: 0.15)
                                    : (_isPdfPath(path)
                                        ? Colors.red.withValues(alpha: 0.15)
                                        : Colors.amber.withValues(alpha: 0.15)),
                              ),
                              child: Text(
                                _isImagePath(path)
                                    ? 'IMAGE'
                                    : (_isPdfPath(path) ? 'PDF' : 'DOC'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _isImagePath(path)
                                      ? Colors.blue
                                      : (_isPdfPath(path)
                                          ? Colors.red
                                          : Colors.amber.shade800),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (_fileSizeText != null)
                              Text(
                                _fileSizeText!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _service.getFileName(path),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tap to view / zoom',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions: Change & Remove
                if (!widget.isReadOnly) ...[
                  IconButton(
                    icon: const Icon(Icons.sync_rounded, size: 20),
                    tooltip: 'Change attachment',
                    visualDensity: VisualDensity.compact,
                    onPressed: _showChangeOptions,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    tooltip: 'Remove attachment',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      widget.onAttachmentChanged(null);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
