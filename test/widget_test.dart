import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kurdpoint/main.dart';
import 'package:kurdpoint/providers/auth_provider.dart';
import 'package:kurdpoint/providers/theme_provider.dart';
import 'package:kurdpoint/providers/language_provider.dart';
import 'package:kurdpoint/providers/notification_provider.dart';
import 'package:kurdpoint/providers/data_cache_provider.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (ctx) => AuthProvider()),
          ChangeNotifierProvider(create: (ctx) => ThemeProvider()),
          ChangeNotifierProvider(create: (ctx) => LanguageProvider()),
          ChangeNotifierProvider(create: (ctx) => NotificationProvider()),
          ChangeNotifierProvider(create: (ctx) => DataCacheProvider()),
        ],
        child: const MyApp(seenOnboarding: false),
      ),
    );

    // Verify that the app starts up
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
