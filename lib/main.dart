import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:highschool_demo_1/rooms.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyA6HRHaCnQEpyOxjVBsWKm_lkz77syJNSU",
          projectId: "highschool-demo",
          messagingSenderId: "521365258409",
          appId: "1:521365258409:web:1410432f020193062929b8"));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(),
        useMaterial3: true,
      ),
      home: const RoomsPage(),
    );
  }
}
