import 'package:flutter_test/flutter_test.dart';
import 'package:cash_book/data/models/category_model.dart';
import 'package:cash_book/data/models/person_model.dart';
import 'package:cash_book/main.dart';
import 'package:cash_book/ui/view_models/cash_book_view_model.dart';

void main() {
  testWidgets('CashBookApp smoke test', (WidgetTester tester) async {
    final viewModel = CashBookViewModel();
    viewModel.seedTestData(
      categories: CategoryModel.defaultCategories,
      transactions: [],
      people: [PersonModel.defaultCurrentUser],
    );

    await tester.pumpWidget(CashBookApp(viewModel: viewModel, showSplash: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Cash Book'), findsWidgets);
    expect(find.text('Cash In'), findsWidgets);
    expect(find.text('Cash Out'), findsWidgets);
  });
}
