import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Contract for handling transaction receipt & document attachments.
/// Follows Dependency Inversion Principle (DIP) and Single Responsibility Principle (SRP).
abstract class IAttachmentService {
  /// Captures a photo using device camera and saves to persistent storage.
  Future<String?> captureFromCamera();

  /// Picks an image from the device photo gallery and saves to persistent storage.
  Future<String?> pickFromGallery();

  /// Picks a document (PDF, DOC, TXT, etc.) and saves to persistent storage.
  Future<String?> pickDocument({List<String>? allowedExtensions});

  /// Deletes an attachment file from persistent storage if it exists.
  Future<void> deleteAttachment(String? path);

  /// Returns clean file name for display.
  String getFileName(String path);

  /// Returns file size in bytes, or 0 if file does not exist.
  Future<int> getFileSizeBytes(String path);

  /// Formats byte size into human readable string (e.g., 2.4 MB, 450 KB).
  String formatFileSize(int bytes);
}

class AttachmentService implements IAttachmentService {
  final ImagePicker? imagePicker;

  AttachmentService({this.imagePicker});

  ImagePicker get _picker => imagePicker ?? ImagePicker();

  @override
  Future<String?> captureFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (photo == null) return null;
      return await _persistPickedFile(photo.path);
    } catch (e) {
      debugPrint('AttachmentService.captureFromCamera error: $e');
      return null;
    }
  }

  @override
  Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null) return null;
      return await _persistPickedFile(image.path);
    } catch (e) {
      debugPrint('AttachmentService.pickFromGallery error: $e');
      return null;
    }
  }

  @override
  Future<String?> pickDocument({List<String>? allowedExtensions}) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions ??
            const ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'png', 'jpg', 'jpeg'],
      );
      if (files.isEmpty) return null;
      final rawPath = files.first.path;
      if (rawPath == null) return null;
      return await _persistPickedFile(rawPath);
    } catch (e) {
      debugPrint('AttachmentService.pickDocument error: $e');
      return null;
    }
  }

  @override
  Future<void> deleteAttachment(String? path) async {
    if (path == null || path.trim().isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('AttachmentService.deleteAttachment error: $e');
    }
  }

  @override
  String getFileName(String path) {
    if (path.isEmpty) return '';
    return p.basename(path);
  }

  @override
  Future<int> getFileSizeBytes(String path) async {
    if (path.isEmpty) return 0;
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      debugPrint('AttachmentService.getFileSizeBytes error: $e');
    }
    return 0;
  }

  @override
  String formatFileSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<String?> _persistPickedFile(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return sourcePath;

      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(p.join(appDir.path, 'attachments'));
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final ext = p.extension(sourcePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'receipt_$timestamp$ext';
      final destinationPath = p.join(attachmentsDir.path, fileName);

      final savedFile = await sourceFile.copy(destinationPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('AttachmentService._persistPickedFile copy failed, fallback to original: $e');
      return sourcePath;
    }
  }
}
