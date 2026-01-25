//screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

// ЭКРАН НАСТРОЕК ПРИЛОЖЕНИЯ
class SettingsScreen extends StatefulWidget{
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState () => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>{
  @override
  Widget build(BuildContext context){
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final settings = settingsProvider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ЗАГОЛОВОК
          const Text(
            'Настройки приложения',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // РАЗДЕЛ: ВНЕШНИЙ ВИД
          _buildSectionHeader('Внешний вид'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Тёмная тема'),
              subtitle: const Text('Включить тёмный режим'),
              trailing: Switch(
                  value: settings.isDarkMode,
                  onChanged: (value) async {
                    await settingsProvider.toggleDarkMode();
                  },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // РАЗДЕЛ: ЗВУКИ
          _buildSectionHeader('Звуки'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Звуковые уведомления'),
              subtitle: const Text('Звук при завершении таймера'),
              trailing: Switch(
                  value: settings.soundEnabled,
                  onChanged: (value) async {
                    await settingsProvider.toogleSound();
                  },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // РАЗДЕЛ: ТРЕНИРОВКА
          _buildSectionHeader('Тренировка'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('Время отдыха по умолчанию'),
                  subtitle: Text('${settings.defaultRestTime} секунд'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Slider(
                    value: settings.defaultRestTime.toDouble(),
                    min: 30,
                    max: 180,
                    divisions: 10,
                    label: '${settings.defaultRestTime} сек',
                    onChanged: (value) async {
                      await settingsProvider.setDefaultRestTime(value.toInt());
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // РАЗДЕЛ: ДАННЫЕ
          _buildSectionHeader('Данные'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete, color:Colors.red),
              title: const Text('Очистить все данные'),
              subtitle: const Text('Удалить все тренировки и настройки'),
              onTap: _showClearDataDialog,
            ),
          ),
        ],
      ),
    );
  }

  // ЗАГОЛОВОК РАЗДЕЛА
  Widget _buildSectionHeader(String title){
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  // ДИАЛОГ ОЧИСТКИ ДАННЫХ
  void _showClearDataDialog(){
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Очистить все данные?'),
          content: const Text(
              'Это действие удалит все тренировки, историю и настройки'
                  'Восстановить данные будет невозможно.'
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
            ),
            ElevatedButton(
                onPressed: () async {
                  // ЗДЕСЬ БУДЕТ ЛОГИКА ОЧИСТКИ ДАННЫХ
                  // Пока просто закрываем диалог
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Функция очистки в разработке'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              child: const Text('Очистить'),
            ),
          ],
        ),
    );
  }
}