import 'package:fieldserviceapp/core/router/app_router.dart';
import 'package:fieldserviceapp/core/theme/theme_provider.dart';
import 'package:fieldserviceapp/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    final router = buildRouter(container);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: FieldServiceApp(router: router),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
