import 'package:flutter/material.dart';
import 'screens/gallery_screen.dart';

//Точка запуска приложения
void main() {
  runApp(const Gallery());
}

/// Основной виджет приложения
class Gallery extends StatelessWidget {
  const Gallery({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const GalleryScreen(),
    );
  }
}
