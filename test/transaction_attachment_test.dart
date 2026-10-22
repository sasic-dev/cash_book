import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cash_book/data/models/transaction_model.dart';
import 'package:cash_book/data/models/transaction_type.dart';
import 'package:cash_book/data/services/attachment_service.dart';
import 'package:cash_book/ui/widgets/attachment_picker_box.dart';

class FakeAttachmentService implements IAttachmentService {
  String? nextCameraResult;
  String? nextGalleryResult;
  String? nextDocResult;
  String? deletedPath;

  @override
  Future<String?> captureFromCamera() async => nextCameraResult;

  @override
  Future<String?> pickFromGallery() async => nextGalleryResult;

  @override
  Future<String?> pickDocument({List<String>? allowedExtensions}) async =>
      nextDocResult;

  @override
  Future<void> deleteAttachment(String? path) async {
    deletedPath = path;
  }

  @override
  String getFileName(String path) {
    if (path.isEmpty) return '';
    return path.split(RegExp(r'[/\\]')).last;
  }

  @override
  Future<int> getFileSizeBytes(String path) async {
    return 1024 * 512; // 512 KB
  }

  @override
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

void main() {
  group('TransactionModel Attachment Unit Tests', () {
    test('TransactionModel handles optional attachmentPath seamlessly', () {
      final txWithout = TransactionModel(
        id: 'tx_1',
        amount: 500,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        date: DateTime.now(),
        title: 'Dinner bill',
      );

      expect(txWithout.hasAttachment, isFalse);
      expect(txWithout.attachmentPath, isNull);
      expect(txWithout.isImageAttachment, isFalse);
      expect(txWithout.isPdfAttachment, isFalse);

      final txWithImage = txWithout.copyWith(
        attachmentPath: '/storage/receipts/bill_101.jpg',
      );

      expect(txWithImage.hasAttachment, isTrue);
      expect(txWithImage.attachmentPath, equals('/storage/receipts/bill_101.jpg'));
      expect(txWithImage.isImageAttachment, isTrue);
      expect(txWithImage.isPdfAttachment, isFalse);

      final txWithPdf = txWithout.copyWith(
        attachmentPath: '/storage/docs/invoice_may.pdf',
      );

      expect(txWithPdf.hasAttachment, isTrue);
      expect(txWithPdf.isPdfAttachment, isTrue);
      expect(txWithPdf.isImageAttachment, isFalse);

      // Test clearAttachment
      final txCleared = txWithImage.copyWith(clearAttachment: true);
      expect(txCleared.hasAttachment, isFalse);
      expect(txCleared.attachmentPath, isNull);
    });

    test('TransactionModel serialization preserves attachmentPath', () {
      final tx = TransactionModel(
        id: 'tx_serialized',
        amount: 1200,
        type: TransactionType.expense,
        categoryId: 'cat_groceries',
        date: DateTime(2026, 10, 15, 14, 30),
        title: 'Supermarket shopping',
        paymentMode: 'UPI',
        baseInrAmount: 1200,
        attachmentPath: '/data/user/0/cash_book/attachments/receipt_999.png',
      );

      // JSON / Map serialization
      final map = tx.toMap();
      expect(map['attachmentPath'], equals('/data/user/0/cash_book/attachments/receipt_999.png'));
      final fromMap = TransactionModel.fromMap(map);
      expect(fromMap.attachmentPath, equals(tx.attachmentPath));

      // SQLite serialization
      final sqliteMap = tx.toSqliteMap();
      expect(sqliteMap['attachment_path'], equals('/data/user/0/cash_book/attachments/receipt_999.png'));
      final fromSqlite = TransactionModel.fromSqliteMap(sqliteMap);
      expect(fromSqlite.attachmentPath, equals(tx.attachmentPath));
      expect(fromSqlite.hasAttachment, isTrue);
      expect(fromSqlite.isImageAttachment, isTrue);
    });
  });

  group('AttachmentService File Formatting Tests', () {
    test('formatFileSize formats human-readable units', () {
      final service = AttachmentService();
      expect(service.formatFileSize(0), equals(''));
      expect(service.formatFileSize(500), equals('500 B'));
      expect(service.formatFileSize(1024 * 150), equals('150.0 KB'));
      expect(service.formatFileSize(1024 * 1024 * 3), equals('3.0 MB'));
    });

    test('getFileName extracts basename accurately', () {
      final service = AttachmentService();
      expect(service.getFileName(''), equals(''));
      expect(
        service.getFileName('c:/data/receipts/bill_march.pdf'),
        equals('bill_march.pdf'),
      );
    });
  });

  group('AttachmentPickerBox Widget Tests', () {
    testWidgets('Renders optional header and picker buttons when empty',
        (tester) async {
      final fakeService = FakeAttachmentService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttachmentPickerBox(
              attachmentPath: null,
              attachmentService: fakeService,
              onAttachmentChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Receipt / Document'), findsOneWidget);
      expect(find.text('Optional'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Doc/PDF'), findsOneWidget);
    });

    testWidgets('Tapping Camera button calls captureFromCamera and triggers callback',
        (tester) async {
      String? changedAttachment;
      final fakeService = FakeAttachmentService();
      fakeService.nextCameraResult = '/data/attachments/receipt_cam_01.jpg';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttachmentPickerBox(
              attachmentPath: null,
              attachmentService: fakeService,
              onAttachmentChanged: (val) => changedAttachment = val,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      expect(changedAttachment, equals('/data/attachments/receipt_cam_01.jpg'));
    });

    testWidgets('Renders attached file preview and allows removing attachment',
        (tester) async {
      String? currentAttachment = '/data/attachments/grocery_invoice.pdf';
      final fakeService = FakeAttachmentService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AttachmentPickerBox(
                  attachmentPath: currentAttachment,
                  attachmentService: fakeService,
                  onAttachmentChanged: (val) {
                    setState(() {
                      currentAttachment = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('grocery_invoice.pdf'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      // Tap remove button
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(currentAttachment, isNull);
      expect(find.text('Camera'), findsOneWidget);
    });

    testWidgets('Past month read-only mode disables picker actions',
        (tester) async {
      final fakeService = FakeAttachmentService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttachmentPickerBox(
              attachmentPath: null,
              isReadOnly: true,
              attachmentService: fakeService,
              onAttachmentChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('No receipt or document attached'), findsOneWidget);
      expect(find.text('Camera'), findsNothing);
    });
  });
}
