// main.dart
import 'package:flutter/material.dart';
import 'screens/templates_screen.dart';


// ГЛАВНАЯ ФУНКЦИЯ
void main(){
  runApp(const WorkoutApp());
}

// КОРНЕВОЙ ВИДЖЕТ ПРИЛОЖЕНИЯ
class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'Тренировки', //Название приложения
      theme: ThemeData(
        primarySwatch: Colors.blue, //основной цвет
        useMaterial3: true,
      ),
      home: const TemplatesScreen(), //Стартовый экран
      debugShowCheckedModeBanner: false, //убираем` лейбл DEBUG
    );
  }
}