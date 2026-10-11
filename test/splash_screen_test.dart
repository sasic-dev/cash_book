import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cash_book/data/models/category_model.dart';
import 'package:cash_book/data/models/person_model.dart';
import 'package:cash_book/main.dart';
import 'package:cash_book/ui/screens/splash_screen.dart';
import 'package:cash_book/ui/view_models/cash_book_view_model.dart';

void main() {
  testWidgets('SplashScreen displays logo and app title cleanly as minimal launch screen',
      (WidgetTester tester) async {
    final viewModel = CashBookViewModel();
    viewModel.seedTestData(
      categories: CategoryModel.defaultCategories,
      transactions: [],
      people: [PersonModel.defaultCurrentUser],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          injectedViewModel: viewModel,
          duration: const Duration(seconds: 10), // long duration so it doesn't navigate immediately
        ),
      ),
    );

    // Initial frame
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify clean launch screen elements are present
    expect(find.text('Cash Book'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('SplashScreen navigates to HomeScreen after duration',
      (WidgetTester tester) async {
    final viewModel = CashBookViewModel();
    viewModel.seedTestData(
      categories: CategoryModel.defaultCategories,
      transactions: [],
      people: [PersonModel.defaultCurrentUser],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          injectedViewModel: viewModel,
          duration: const Duration(milliseconds: 100),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // Verify HomeScreen is reached
    expect(find.text('Cash In'), findsWidgets);
    expect(find.text('Cash Out'), findsWidgets);
  });

  testWidgets('CashBookApp launches directly into HomeScreen by default (no splash screen)',
      (WidgetTester tester) async {
    final viewModel = CashBookViewModel();
    viewModel.seedTestData(
      categories: CategoryModel.defaultCategories,
      transactions: [],
      people: [PersonModel.defaultCurrentUser],
    );

    // No showSplash specified, defaults to false
    await tester.pumpWidget(CashBookApp(viewModel: viewModel));
    await tester.pumpAndSettle();

    expect(find.text('Cash Book'), findsWidgets);
    expect(find.text('Cash In'), findsWidgets);
    expect(find.text('Cash Out'), findsWidgets);
  });
}
