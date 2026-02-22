//screens/settings_screen.dart

import 'package:fitflow/screens/templates_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/storage_service.dart';


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

          // РАЗДЕЛ: Уведомления
          _buildSectionHeader('Уведомления'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Звуковые оповещения'),
              subtitle: const Text('Звук при завершении таймера или тренировки'),
              trailing: Switch(
                  value: settings.soundEnabled,
                  onChanged: (value) async {
                    await settingsProvider.toogleSound();
                  },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Уведомления'),
              subtitle: const Text('Уведомления о завершении таймера и тренировки'),
              trailing: Switch(
                value: settings.notificationsEnabled,
                onChanged: (value) async {
                  await settingsProvider.toggleNotifications();
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // РАЗДЕЛ: ДАННЫЕ
          _buildSectionHeader('Данные'),
          Card(
            child: ListTile(
              leading: Icon(Icons.delete, color:Theme.of(context).colorScheme.error),
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
          color: Theme.of(context).colorScheme.primary,
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
              onPressed: () async{
                // ОЧИЩАЕМ ХРАНИЛИЩЕ
                await StorageService.clearAllData();
                Navigator.pop(context);
              },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              child: const Text('Очистить'),
            ),
          ],
        ),
    );
  }
}