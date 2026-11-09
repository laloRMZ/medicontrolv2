import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medicontrol/main.dart';

void main() {
  testWidgets('MediControl app loads the login screen', (tester) async {
    SharedPreferences.setMockInitialValues({
      'isLoggedIn': true,
      'userEmail': 'eduardo@medicontrol.com',
    });
    await tester.pumpWidget(const MediControl());

    expect(find.text('MediControl'), findsAtLeastNWidgets(1));
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('login navigates to the app shell when credentials are filled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MediControl());

    await tester.enterText(
      find.byType(TextField).at(0),
      'eduardo@medicontrol.com',
    );
    await tester.enterText(find.byType(TextField).at(1), '123456');

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
