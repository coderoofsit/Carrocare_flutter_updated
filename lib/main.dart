import 'package:carrocare_flutter/app/app.dart';
import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const CarroCareApp());
}
