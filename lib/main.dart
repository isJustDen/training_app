// main.dart
import 'package:flutter/material.dart';
import 'screens/templates_screen.dart';
import 'models/exercise.dart';
import 'models/workout_template.dart';

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

// ВРЕМЕННЫЙ ЭКРАН ДЛЯ ТЕСТИРОВАНИЯ МОДЕЛЕЙ
class TestScreen extends StatefulWidget{
  const TestScreen({super.key});

  @override
  State<TestScreen> createState()=> _TestScreenState();
}
class _TestScreenState extends State<TestScreen>{
  // СОЗДАЕМ ТЕСТОВЫЕ ДАННЫЕ
  final WorkoutTemplate testTemplate = WorkoutTemplate(
    id: '1',
    name: 'Тренировка груди',
    dayOfWeek: 'Понедельник',
    exercises: [
      Exercise(id: '1', name: 'Жим штанги лёжа', weight: 80, sets: 4, reps: 10),
      Exercise(id: '2', name: 'Разводка гантелей', weight: 20, sets: 3, reps: 12),
      Exercise(id: '3', name: 'Отжимания от брусьев', sets: 3, reps: 15),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

@override
Widget build(BuildContext context){
  return Scaffold(
    appBar: AppBar(
      title: const Text ('Test models'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ОТОБРАЖАЕМ ИНФОРМАЦИЮ О ТРЕНИРОВКЕ
          Text(
            'Шаблон ${testTemplate.name}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text('День: ${testTemplate.dayOfWeek}'),
          Text('Упражнений: ${testTemplate.exercises.length}'),

          const SizedBox(height: 20),
          const Text(
            'Упражнения:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          // СПИСОК УПРАЖНЕНИЙ
          Expanded(
              child: ListView.builder(
                  itemCount: testTemplate.exercises.length,
                  itemBuilder: (context, index){
                  final exercise = testTemplate.exercises[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text(exercise.name),
                      subtitle: Text(
                        '${exercise.sets}x${exercise.reps} по ${exercise.weight} кг',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState((){
                            testTemplate.removeExercise(index);
                          });
                        },
                      ),
                    ),
                  );
                  },
              ),
          ),

      // КНОПКА ДЛЯ ТЕСТИРОВАНИЯ COPYWITH
        ElevatedButton(
            onPressed:(){
              // СОЗДАЕМ КОПИЮ С ИЗМЕНЕННЫМ ИМЕНЕМ
              final updated = testTemplate.copyWith(
                name: '${testTemplate.name} (изменено)',
              );
              print('Оригинал: $testTemplate');
              print('Копия $updated');
            },
              child: const Text('Тест copyWith()'),
            ),
          ],
        ),
      ),
    );
  }
}

//Давай двигаться более плавно. Выдавай информацию порционно. Еще, давай проект зальём в git hub, чтобы сохранять прогресс





// ЭКРАН ДОМАШНЕЙ СТРАНИЦЫ
// class HomeScreen extends StatefulWidget{
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// // КЛАСС СОСТОЯНИЯ для HomeScreen
// class _HomeScreenState extends State<HomeScreen>{
//   int _workoutCount = 0;
//   List<String> _workouts = [];
//
//   void _addWorkout(){
//     setState(() {  // setState() - КРИТИЧЕСКИ ВАЖНЫЙ МЕТОД Сообщает Flutter, что состояние изменилось и нужно перерисовать UI. Без setState() UI не обновится
//       _workoutCount++;
//       _workouts.add('Тренировка $_workoutCount');
//     });
//   }
//
//   void _removeWorkout(int index) {
//     setState(() {
//       _workouts.removeAt(index);
//     });
//   }
//
//   // build() метод - описывает UI
//   @override
//   Widget build(BuildContext context) {
//     // Scaffold - каркас экрана Material Design
//     return Scaffold(
//       // AppBar - верхняя панель
//     appBar: AppBar(
//       title: const Text('Мои тренировки'),
//       centerTitle: true,
//       titleTextStyle: TextStyle(fontSize: 30, color: Colors.purpleAccent),
//     ),
//       // body - основное содержимое
//       body: _buildBody(),
//
//       floatingActionButton: FloatingActionButton(
//           onPressed: _addWorkout,
//           child: const Icon(Icons.add),
//           tooltip: 'Добавить тренировку',
//       ),
//     );
//   }
//
//   // ПРИВАТНЫЙ МЕТОД ДЛЯ ПОСТРОЕНИЯ ТЕЛА ЭКРАНА
//   Widget _buildBody(){
//     if (_workouts.isEmpty){
//       return const Center(
//         child: Text(
//           'Нет тренировок\nНажмите "+" чтобы добавить',
//           textAlign: TextAlign.center,
//           style: TextStyle(fontSize: 22, color: Colors.blueAccent),
//         ),
//       );
//     }
//
//     return ListView.builder(
//       itemCount: _workouts.length,
//       itemBuilder: (context, index) {
//         return Card(
//           margin: const EdgeInsets.all(8.0),
//           child: ListTile(
//             leading: const Icon(Icons.fitness_center),
//             title: Text('${_workouts[index]}'),
//             subtitle: Text('${index + 1} упражнений'),
//             trailing: IconButton(
//               icon: const Icon(Icons.delete, color: Colors.red),
//               onPressed: () => _removeWorkout(index),
//             ),
//             onTap: (){
//               // Обработчик нажатия на элемент
//             print('Нажали на : ${_workouts[index]}');
//             },
//           ),
//         );
//       },
//     );
//   }
// }