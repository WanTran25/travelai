import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/travel_provider.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => TravelProvider(),
      child: const TravelApp(),
    ),
  );
}
