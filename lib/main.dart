import 'package:flutter/material.dart';
import 'package:pawprints/screens/login/loginScreen.dart';
import 'package:pawprints/screens/primaryScreen.dart';
import 'package:provider/provider.dart';
import 'package:pawprints/providers/login/loginProvider.dart';
import 'package:pawprints/providers/profile/profileProvider.dart';
import 'package:pawprints/providers/timeline/timelineProvider.dart';
import 'package:pawprints/providers/primaryProvider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) =>
                LoginProvider()), // Provider for the login state of the app
        ChangeNotifierProvider(
            create: (_) => TimelineProvider()), // Provider for the match screen
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(
            create: (_) => PrimaryProvider()) // Provider for the match screen
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': ((context) => LoginScreen()),
        '/primary': ((context) => PrimaryScreen()),
      },
    );
  }
}
