//screens/settings_screen.dart

import 'package:fitflow/screens/templates_screen.dart';
import 'package:fitflow/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      body: CustomScrollView(
        slivers: [
        AppHeader(title: 'Настройки', subtitle: 'Персонализация прилоежния'),

        SliverToBoxAdapter(
          child: ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsetsGeometry.fromLTRB(16, 8, 16, 80),
            children: [
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
                      await settingsProvider.toggleSound();
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

              // РАЗДЕЛ: ЭКРАН
              _buildSectionHeader('Экран во время тренировки'),
              _buildDimSettings(),
              const SizedBox(height: 8),

              // РАЗДЕЛ: ДАННЫЕ
              _buildSectionHeader('Данные'),

              // КНОПКА ОЧИСТКИ СТАТИСТИКИ
              Card(
                child: ListTile(
                  leading: Icon(Icons.assessment, color:Theme.of(context).colorScheme.error),
                  title: const Text('Очистить статистику'),
                  subtitle: const Text('Удалить историю тренировок (шаблоны сохранятся)'),
                  onTap: _showClearStatsDialog,
                ),
              ),

              // КНОПКА СБРОСА ШАБЛОНОВ
              Card(
                child: ListTile(
                  leading: Icon(Icons.refresh, color: Theme.of(context).colorScheme.error),
                  title: const Text('Сбросить шаблоны'),
                  subtitle: const Text('Восстановить заводские шаблоны тренировок'),
                  onTap: _showResetTemplatesDialog,
                ),
              ),

              // КНОПКА ПОЛНОГО СБРОСА
              Card(
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
                  title: const Text('Сброс до заводских настроек'),
                  subtitle: const Text('Удалить ВСЕ данные и вернуть исходное состояние'),
                  onTap: _showFactoryResetDialog,
                ),
              ),

              Card(
                child: ListTile(
                  leading: Icon(Icons.category_rounded, color: Theme.of(context).colorScheme.error),
                  title: const Text('Сбросить категории'),
                  subtitle: const Text('Восстановить категории Зал и Улица'),
                  onTap: () async {
                    await StorageService.resetCategoriesToDefault();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Категории восстановлены'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),

              // РАЗДЕЛ: О ПРИЛОЖЕНИИ
              _buildSectionHeader('О приложении'),
              Card(
                child: ListTile(
                  leading: Icon(Icons.person_pin_circle_sharp, color:Theme.of(context).colorScheme.primary),
                  title: const Text('Cделано при самостоятельном энтузиазме Denis S. (Andromeda)'),
                  subtitle: const Text('Предложения и жалобы прнимаются по адресу den.work.zav@gmail.com.\nВсех благ!\nVersioN: 1.0.0'),
                ),
              ),

              _buildSectionHeader('Поддержка'),
              Card(
                child: ListTile(
                  leading: Icon(Icons.favorite, color: Colors.red.shade400),
                  title: const Text('Поддержать автора'),
                  subtitle: const Text('Сказать спасибо и поддержать проект'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showSupportDialog,
                ),
              ),
            ],
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

  // ДИАЛОГ ОЧИСТКИ СТАТИСТИКИ
  void _showClearStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить статистику?'),
        content: const Text(
            'Вся история тренировок будет удалена.\n'
                'Шаблоны упражнений и настройки останутся.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              await StorageService.clearStatsOnly();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Статистика очищена'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

// ДИАЛОГ СБРОСА ШАБЛОНОВ
  void _showResetTemplatesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить шаблоны?'),
        content: const Text(
            'Все ваши шаблоны тренировок будут заменены на заводские.\n'
                'История тренировок сохранится.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              await StorageService.resetTemplatesToDefault();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Шаблоны восстановлены'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }

  // ДИАЛОГ ПОЛНОГО СБРОСА
  void _showFactoryResetDialog(){
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Полный сброс?'),
          content: const Text(
              'ВНИМАНИЕ! Это действие:\n'
                  '• Удалит ВСЕ тренировки и историю\n'
                  '• Удалит ВСЕ настройки\n'
                  '• Удалит пользовательские упражнения\n'
                  '• Восстановит заводские шаблоны\n\n'
                  'Восстановить данные будет невозможно!'
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                // ОЧИЩАЕМ ХРАНИЛИЩЕ
                await StorageService.factoryReset();
                Navigator.pop(context);

                // Перезапустить приложение (опционально)
                // Можно показать диалог о перезапуске
                showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      title: const Text('Сброс выполнен'),
                      content: const Text('Приложение будет перезапущено'),
                      actions: [
                        ElevatedButton(
                            onPressed: (){
                              // Выход из приложения
                              SystemNavigator.pop();
                              setState(() {});
                            } ,
                            child: const Text('Ок'),
                        ),
                      ],
                    ),
                );
              },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              child: const Text('Сбросить всё'),
            ),
          ],
        ),
    );
  }



  //МЕТОД ДЛЯ ЗАТЕМНЕНИЯ ЭКРАНА
  Widget _buildDimSettings() {
    final settings = context.watch<SettingsProvider>().settings;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          // ПЕРЕКЛЮЧАТЕЛЬ ВКЛ/ВЫКЛ
          SwitchListTile(
            title: const Text('Затемнение экрана'),
            subtitle: const Text('Экран тускнеет в паузе между подходами'),
            secondary: Icon(
              Icons.screen_lock_portrait_rounded,
              color: settings.dimScreenEnabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            value: settings.dimScreenEnabled,
            onChanged: (value) {
              context.read<SettingsProvider>().updateSettings(
                settings.copyWith(dimScreenEnabled: value),
              );
            },
          ),

          // СЛАЙДЕР ВРЕМЕНИ — только если затемнение включено
          if(settings.dimScreenEnabled) ...[
            const Divider(height: 1),
            Padding(
                padding: const EdgeInsetsGeometry.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.timer_outlined,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            const Text(
                              'Задержка затемнения',
                              style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        // ТЕКУЩЕЕ ЗНАЧЕНИЕ
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${settings.dimAfterSeconds} сек',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                        value: settings.dimAfterSeconds.toDouble(),
                        min: 5,
                        max: 60,
                        divisions: 11,
                        label: '${settings.dimAfterSeconds} сек',
                        onChanged: (value) {
                          context.read<SettingsProvider>().updateSettings(
                              settings.copyWith(dimAfterSeconds: value.round()),
                          );
                        }
                    ),
                    // ПОДСКАЗКИ ПО КРАЯМ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '5 сек',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        Text(
                          '60 сек',
                          style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
            ),
          ]
        ],
      ),
    );
  }

  //ПОДДЕРЖАТЬ АВТОРА РАЗДЕЛ
  void _showSupportDialog() {
    final cardNumber = '';
    final sbpNumber = '';
    final cryptoWallet = 'Мой кошелек крипты';
    final boostyLink = 'link';

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.favorite, color: Colors.red.shade400, size: 28),
              const SizedBox(width: 8),
              const Text('Поддержать проект'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Если приложение помогает и вы хотите сказать "спасибо":',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

                // КАРТА
                _buildDonationItem(
                  icon: Icons.credit_card,
                  title: 'Карта',
                  value: cardNumber,
                  color: Colors.green.shade700,
                  onTap: () => _copyToClipboard(cardNumber, 'Номер карты скопирован'),
                ),

                const SizedBox(height: 12),

                // СБП
                _buildDonationItem(
                  icon: Icons.phone_android,
                  title: 'СБП',
                  value: sbpNumber,
                  color: Colors.blue.shade700,
                  onTap: () => _copyToClipboard(sbpNumber, 'Номер СБП скопирован'),
                ),

                const SizedBox(height: 12),

                // КРИПТО
                _buildDonationItem(
                  icon: Icons.currency_bitcoin,
                  title: 'Крипто',
                  value: cryptoWallet,
                  color: Colors.orange.shade700,
                  onTap: () => _copyToClipboard(cryptoWallet, 'Адрес кошелька скопирован'),
                ),

                const SizedBox(height: 12),

                // BOOSTY
                _buildDonationItem(
                  icon: Icons.bolt_rounded,
                  title: 'Boosty',
                  value: boostyLink,
                  color: Colors.yellow.shade700,
                  onTap: () => _copyToClipboard(boostyLink, 'Адрес Boosty скопирован'),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red.shade400, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Приложение остаётся полностью бесплатным для всех.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Спасибо, что пользуетесь! 💪',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
    );
  }

  // ВИДЖЕТ ДЛЯ ОТОБРАЖЕНИЯ РЕКВИЗИТА
  Widget _buildDonationItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Копировать',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

// МЕТОД ДЛЯ КОПИРОВАНИЯ В БУФЕР ОБМЕНА
  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

}