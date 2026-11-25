import 'package:flutter/material.dart';

import 'data/database.dart';
import 'screens/tareas_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GestorTareasApp(db: AppDatabase()));
}

class GestorTareasApp extends StatelessWidget {
  const GestorTareasApp({super.key, required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFBE6A79),
          secondary: const Color(0xFFDDA8A5),
          onSecondary: const Color(0xFFDDA8A5),
          secondaryContainer: const Color(0xFFC07A86),
          onSecondaryContainer: const Color.fromARGB(255, 179, 107, 119),
          secondaryFixed:  const Color(0xFFC07A86),
          onSecondaryFixed: const Color(0xFFDC9D96),
          onSecondaryFixedVariant: const Color(0xFFC07A86),
          secondaryFixedDim: const Color(0xFFEFD3CB) 
        ),
        useMaterial3: true,

        appBarTheme: const AppBarTheme(
          foregroundColor: Color(0xFF7A3B47), 
          titleTextStyle: TextStyle(
            color: Color(0xFF7A3B47),        
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFFBE6A79),
          ),
        ),
        
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFBE6A79),
            foregroundColor: Colors.white,
          ),
        ),

      ),
      home: TareasPage(db: db),
    );
  }
}
