//screens/categories_screen.dart

import 'package:fitflow/screens/workout_generator_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/workout_category.dart';
import '../models/workout_template.dart';
import '../services/storage_service.dart';
import 'edit_template_screen.dart';
import 'workout_screen.dart';

// ЭКРАН КАТЕГОРИЙ
class CategoriesScreen  extends StatefulWidget{
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
  with SingleTickerProviderStateMixin {
  List<WorkoutCategory> _categories = [];
  List<WorkoutTemplate> _templates = [];
  bool _isLoading = true;

  // AnimationController для анимации появления карточек
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      StorageService.loadCategories(),
      StorageService.loadTemplates(),
    ]);

    setState(() {
      _categories = results[0] as List<WorkoutCategory>;
      _templates = results[1] as List<WorkoutTemplate>;
      _isLoading = false;
    });

    _animController.forward();
  }

  // ПОЛУЧИТЬ ШАБЛОНЫ ГРУППЫ по их ID
  List<WorkoutTemplate> _getGroupTemplates(WorkoutGroup group) {
    return _templates
        .where((t) => group.templateIds.contains(t.id))
        .toList();
  }

  // ПОЛУЧИТЬ ШАБЛОНЫ БЕЗ КАТЕГОРИИ
  List<WorkoutTemplate> _getUncategorized() {
    final allCategorized = _categories
        .expand((c) => c.groups)
        .expand((g) => g.templateIds)
        .toSet();
    return _templates.where((t) => !allCategorized.contains(t.id)).toList();
  }

  @override
  Widget build (BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
        slivers: [
          // КРАСИВЫЙ СВОРАЧИВАЮЩИЙСЯ ХЕДЕР
          _buildSliverAppBar(colorScheme),

          // СПИСОК КАТЕГОРИЙ
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // КАТЕГОРИИ
                  ..._categories.asMap().entries.map((entry) {
                    return _buildCategoryCard(
                      entry.value,
                      entry.key,
                    );
                  }),

                  // НЕКАТЕГОРИЗИРОВАННЫЕ (если есть)
                  if (_getUncategorized().isNotEmpty)
                    _buildUncategorizedSection(),
                ]),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // СВОРАЧИВАЮЩИЙСЯ APPBAR — при скролле сжимается
  Widget _buildSliverAppBar(ColorScheme colorScheme){
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true, // Остаётся видимым при скролле
      backgroundColor: colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Тренировки',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.7),
              ],
            ),
          ),
          child: SafeArea(
              child:Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child:Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Дневничёк',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                            '${_categories.length} категорий · ${_templates.length} тренировок',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // КНОПКА ДОБАВИТЬ КАТЕГОРИЮ
                  _buildHeaderButton(
                    icon: Icons.create_new_folder_rounded,
                    onTap: _addCategory,
                    tooltip: 'Новая категория',
                  ),

                  SizedBox(width: 8),

                  // КНОПКА ДОБАВИТЬ КАТЕГОРИЮ
                  _buildHeaderButton(
                    icon: Icons.fitness_center_rounded,
                    onTap: _addTemplate,
                    tooltip: 'Новая тренировка',
                  ),

                  SizedBox(width: 8),

                  _buildHeaderButton(
                    icon: Icons.auto_awesome_rounded,
                    tooltip: 'Генератор',
                    onTap: _openGenerator,
                  ),

                  SizedBox(width: 8),

                  _buildHeaderButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Обновить',
                    onTap: _loadData,
                  ),
                ],
              ),
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  // КАРТОЧКА КАТЕГОРИИ
  Widget _buildCategoryCard(WorkoutCategory category, int index) {
    // Анимация появления с задержкой по индексу
    final animation = CurvedAnimation(
        parent: _animController,
        curve: Interval(
          (index * 0.15).clamp(0.0, 0.8),
            ((index * 0.15) + 0.4).clamp(0.0, 1.0),
        curve: Curves.easeOut,
      ),
    );

    final color = _hexToColor(category.color);

    return AnimatedBuilder(
        animation: animation,
        builder: (context, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
          child: FadeTransition(opacity: animation, child: child,),
        ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ЗАГОЛОВОК КАТЕГОРИИ
            _buildCategoryHeader (category, color),

            // ГРУППЫ ВНУТРИ КАТЕГОРИИ
            ...category.groups.map((group) =>
            _buildGroupSection(category, group, color)
            ),

            // КНОПКА ДОБАВИТЬ ГРУППУ
            _buildAddGroupButton(category, color),
          ],
        ),
      ),
    );
  }

  // ЗАГОЛОВОК КАТЕГОРИИ с эмодзи и кнопками
  Widget _buildCategoryHeader(WorkoutCategory category, Color color){
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // ЭМОДЗИ в цветном круге
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            ),
            child: Center(
              child: Text(category.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12,),

          // НАЗВАНИЕ И СЧЁТЧИК
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text('${category.groups.length} групп · '
                      '${category.groups.expand((g) => g.templateIds).length} тренировок',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
          ),

          // КНОПКИ РЕДАКТИРОВАНИЯ/УДАЛЕНИЯ
          IconButton(
            onPressed: () => _editCategory(category),
            icon: Icon(Icons.edit_rounded, size: 18, color: color,),
            tooltip: 'Редактировать',
          ),
          IconButton(
            onPressed: () => _deleteCategory(category),
            icon: Icon(Icons.delete_rounded, size: 18,
              color: Theme.of(context).colorScheme.error),
            tooltip: 'Удалить',
          ),
        ],
      ),
    );
  }

  // СЕКЦИЯ ГРУППЫ — заголовок + список тренировок
  Widget _buildGroupSection(
      WorkoutCategory category, WorkoutGroup group, Color categoryColor){
    final templates = _getGroupTemplates(group);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ЗАГОЛОВОК ГРУППЫ
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color:  categoryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8,),
              Expanded(
                child: Text(
                  group.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              // КНОПКА ДОБАВИТЬ ТРЕНИРОВКУ В ГРУППУ
              IconButton(
                icon: Icon(Icons.add_rounded, size: 24, color: categoryColor),
                onPressed: () => _addTemplateToGroup(category, group),
                tooltip: 'Добавить тренировку',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 22,
                    color: Theme.of(context).colorScheme.error),
                onPressed: () => _deleteGroup(category, group),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 6,),

          // ТРЕНИРОВКИ В ГРУППЕ
          if (templates.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Text(
                'Нет тренировок - нажмите + чтобы добавить',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...templates.map((t) => _buildTemplateRow(t, category, group, categoryColor)),
          Divider(height: 16, color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        ],
      ),
    );
  }

  // СТРОКА ТРЕНИРОВКИ внутри группы
  Widget _buildTemplateRow(
      WorkoutTemplate template,
      WorkoutCategory category,
      WorkoutGroup group,
      Color color,) {
    return InkWell(
      onTap: () => _openWorkout(template),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            // ЦВЕТНАЯ ТОЧКА
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),

            // НАЗВАНИЕ И ОПИСАНИЕ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${template.dayOfWeek} · ${template.exercises.length} упр.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // КНОПКИ ДЕЙСТВИЙ
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.green, size: 30,),
                onPressed: () => _startWorkout(template),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
            ),
            IconButton(
              icon: Icon(Icons.edit_rounded, color:Theme.of(context).colorScheme.onSurfaceVariant, size: 25,),
              onPressed: () => _editTemplate(template),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
            ),
            // УБРАТЬ ИЗ ГРУППЫ (не удалять тренировку)
            IconButton(
              icon: Icon(Icons.remove_circle_outline_rounded, color: Theme.of(context).colorScheme.error, size: 25,),
              onPressed: () => _removeFromGroup(category, group, template),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
            ),
          ],
        ),
      ),
    );
  }

  // НЕКАТЕГОРИЗИРОВАННЫЕ ТРЕНИРОВКИ
  Widget _buildUncategorizedSection() {
    final uncategorized = _getUncategorized();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.4),
          width: 1
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.inbox_rounded,
                color: colorScheme.onSurfaceVariant, size: 25),
                const SizedBox(width: 8),
                Text(
                    'Без категории',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${uncategorized.length} тренировок',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ...uncategorized.map((t) => ListTile(
            dense: true,
            leading: Icon(Icons.fitness_center_rounded,
              size: 18, color: colorScheme.onSurfaceVariant),
            title: Text(t.name, style: const TextStyle(fontSize: 14)),
            subtitle: Text('${t.dayOfWeek} · ${t.exercises.length} упр.',
              style: TextStyle(fontSize: 11)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.green, size: 30),
                  onPressed: () => _startWorkout(t),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 23),
                  onPressed: () => _editTemplate(t),
                ),
                IconButton(
                  icon: Icon(Icons.delete_rounded, size: 23, color: Theme.of(context).colorScheme.error),
                  onPressed: () => _deleteTemplate(t),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // КНОПКА ДОБАВИТЬ ГРУППУ В КАТЕГОРИЮ
  Widget _buildAddGroupButton( WorkoutCategory category, Color color){
    return Padding(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: () => _addGroup(category),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: color.withOpacity(0.3),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                'Добавить группу',
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FAB — добавить тренировку или категорию
  Widget _buildFab(){
    return FloatingActionButton.extended(
        onPressed: _showAddMenu,
        icon: const Icon(Icons.add_rounded, size: 20,),
      label: const Text('Создать'),
    );
  }

  // МЕНЮ СОЗДАНИЯ
  void _showAddMenu(){
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ИНДИКАТОР DRAG
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildMenuOption(
                icon: Icons.fitness_center_rounded,
                color: Colors.green,
                title: 'Новая тренировка',
                subtitle: 'Создать шаблон тренировки',
                onTap: () {Navigator.pop(context); _addTemplate(); },
              ),
              const SizedBox(height: 8,),
              _buildMenuOption(
                icon: Icons.create_new_folder_rounded,
                color: Colors.blue,
                title: 'Новая категория',
                subtitle: 'Зал, Улица, Дом и т.д.',
                onTap: () {Navigator.pop(context); _addCategory(); },
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

// ══════════════════════════════════════
// МЕТОДЫ CRUD
// ══════════════════════════════════════

  // ДОБАВИТЬ КАТЕГОРИЮ
  void _addCategory(){
    _showCategoryDialog();
  }

  // РЕДАКТИРОВАТЬ КАТЕГОРИЮ
  void _editCategory(WorkoutCategory category){
    _showCategoryDialog(existing: category);
  }

  // ДИАЛОГ СОЗДАНИЯ/РЕДАКТИРОВАНИЯ КАТЕГОРИИ
  void _showCategoryDialog({WorkoutCategory? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    String selectedEmoji = existing?.emoji ?? '💪';
    String selectedColor = existing?.color ?? '#FF2979FF';


  const emojis = ['💪', '🏋️', '🏃', '⚡', '🔥', '🌿', '🏠', '🌳', '🥊', '🎯'];

  const colors = ['#FF2979FF', '#FF00BCD4', '#FF4CAF50',
                  '#FFFF9800', '#FFE91E63', '#FF9C27B0',];

  showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Новая категория': 'Редактировать'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ПОЛЕ НАЗВАНИЯ
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_rounded),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),

                  // ВЫБОР ЭМОДЗИ
                  Text('Иконка', style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: emojis.map((e) => GestureDetector(
                      onTap: () => setDialogState(() => selectedEmoji = e),
                      child: Container(
                          width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: selectedEmoji == e
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: selectedEmoji == e
                                  ?Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                                  :null,
                        ),
                        child: Center(child: Text(e, style: const TextStyle(fontSize: 20))),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),

                  // ВЫБОР ЦВЕТА
                  Text('Цвет', style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: colors.map((c) {
                      final color = _hexToColor(c);
                      final isSelected = selectedColor == c;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = c),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected ? [
                              BoxShadow(color: color.withOpacity(0.5),
                                  blurRadius: 8, spreadRadius: 2)
                            ] : null,
                          ),
                          child: isSelected
                              ? const Icon(
                              Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
              ),
              ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;

                    final category = (existing ?? WorkoutCategory(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: '',
                        emoji: '',
                        color: '',
                        groups: [],
                        createdAt: DateTime.now(),
                    )).copyWith(
                      name: nameController.text,
                      emoji: selectedEmoji,
                      color: selectedColor,
                    );

                    setState(() {
                      if(existing == null) {
                        _categories.add(category);
                      }else {
                        final i = _categories.indexWhere((c) => c.id == existing.id);
                        if (i != -1) _categories[i] = category;
                      }
                    });

                    await StorageService.saveCategories(_categories);
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Сохранить'),
              ),
            ],
          ),
      ),
  );
}

// УДАЛИТЬ КАТЕГОРИЮ
void _deleteCategory(WorkoutCategory category) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title:  const Text('Удалить категорию?'),
          content: Text(
            'Категория "${category.name}" будет удалена.'
                'Тренировки останутся, но перейдут в раздел "Беза категории".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () async {
                  setState(() => _categories.removeWhere((c) => c.id == category.id));
                  await StorageService.saveCategories(_categories);
                },
                child: const Text('Удалить'),
            ),
          ],
        ),
    );
}

  // ДОБАВИТЬ ГРУППУ В КАТЕГОРИЮ
  void _addGroup(WorkoutCategory category){
    final controller = TextEditingController();
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Группа в "${category.name}"'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Название группы',
              hintText: 'Например: Грудь + Трицепс',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.folder_rounded),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена')
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isEmpty) return;

                final group = WorkoutGroup(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: controller.text,
                  templateIds: [],
                );
                final updatedCategory = category.copyWith(
                  groups: [...category.groups, group],
                );

                setState(() {
                  final i = _categories.indexWhere((c) => c.id == category.id);
                  if (i != -1) _categories[i] = updatedCategory;
                });

                await StorageService.saveCategories(_categories);
                if (mounted) Navigator.pop(context);
              } ,
              child: const Text('Создать'),
            ),
          ],
        ),
    );
  }

  // УДАЛИТЬ ГРУППУ
  void _deleteGroup(WorkoutCategory category, WorkoutGroup group){
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Удалить группу?'),
          content: Text(
            'Группа "${group.name}" будет удалена.'
                'Тренировки перейдут в "Без категории".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () async {
                  final updatedCategory = category.copyWith(
                    groups: category.groups.where((g) => g.id != group.id).toList(),
                  );
                  setState(() {
                    final i = _categories.indexWhere((c) => c.id == category.id);
                    if (i != -1) _categories[i] = updatedCategory;
                  });
                  await StorageService.saveCategories(_categories);
                  if (mounted) Navigator.pop(context);
            },
                child: const Text('Удалить'),
            ),
          ],
        ),
    );
  }

  // ДОБАВИТЬ ТРЕНИРОВКУ В ГРУППУ — показываем список доступных
  void _addTemplateToGroup(WorkoutCategory category, WorkoutGroup group) {
    // Тренировки которые ещё не в этой группе
    final available = _templates
        .where((t) => !group.templateIds.contains(t.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет доступных тренировок')),
      );
      return;
    }

   showModalBottomSheet(
       context: context,
       shape: const RoundedRectangleBorder(
         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
       ),
       builder: (context) => Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           Container(
             width: 40, height: 4,
             margin: const EdgeInsets.only(top: 12, bottom: 4),
             decoration: BoxDecoration(
               color: Theme.of(context).colorScheme.outline,
               borderRadius: BorderRadius.circular(2)
             ),
           ),
           Padding(
             padding: const EdgeInsets.all(16),
             child: Text(
               'Добавить в "${group.name}"',
               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
             ),
           ),
           Flexible(
             child: ListView(
               shrinkWrap: true,
               children: [
                 ...available.map((t) => ListTile(
                   leading: const Icon(Icons.fitness_center_rounded),
                   title: Text(t.name),
                   subtitle: Text('${t.exercises.length} упражнений'),
                   onTap: () async {
                     final updatedGroup = group.copyWith(
                       templateIds: [...group.templateIds, t.id],
                     );
                     final updatedCategory = category.copyWith(
                       groups: category.groups
                           .map((g) => g.id == group.id ? updatedGroup : g)
                           .toList(),
                     );
                     setState(() {
                       final i = _categories.indexWhere((c) => c.id == category.id);
                       if (i != -1) _categories[i] = updatedCategory;
                     });
                     await StorageService.saveCategories(_categories);
                     if (mounted) Navigator.pop(context);
                   },
                 )),
               ],
            ),
           ),

           const SizedBox(height: 16,),
         ],
       ),
   );
  }

  // УБРАТЬ ТРЕНИРОВКУ ИЗ ГРУППЫ
  void _removeFromGroup(WorkoutCategory category, WorkoutGroup group, WorkoutTemplate template){
    final updatedGroup = group.copyWith(
      templateIds: group.templateIds.where((id) => id != template.id).toList(),
    );
    final updatedCategory = category.copyWith(
      groups: category.groups
          .map((g) => g.id == group.id ? updatedGroup : g)
          .toList(),
    );
    setState(() {
      final i = _categories.indexWhere((c) => c.id == category.id);
      if (i != -1) _categories[i] = updatedCategory;
    });
    StorageService.saveCategories(_categories);
  }

  // ДОБАВИТЬ НОВЫЙ ШАБЛОН
  void _addTemplate() async {
    final newTemplate = WorkoutTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Новая тренировка',
      dayOfWeek: 'Понедельник',
      exercises: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final templates = await StorageService.loadTemplates();
    templates.add(newTemplate);
    await StorageService.saveTemplates(templates);

    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => EditTemplateScreen(template: newTemplate),
        ),
      );
      if (result != null) _loadData();
    }
  }

  void _editTemplate(WorkoutTemplate template) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => EditTemplateScreen(template: template),
      ),
    );

    if (result != null) {
      final templates = await StorageService.loadTemplates();
      final i = templates.indexWhere((t) => t.id == template.id);
      if (i != -1) templates[i] = result;
      await StorageService.saveTemplates(templates);
      _loadData();
    }
  }

  void _startWorkout(WorkoutTemplate template){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkoutScreen(template: template)),
    ).then((_) => _loadData());
  }

  void _openWorkout(WorkoutTemplate template) => _editTemplate(template);

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length ==6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    } else if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
    return Colors.blue;
  }

  void _deleteTemplate(WorkoutTemplate template) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Удалить тренировку?'),
            content: Text(
                'Вы уверены, что хотите удалить ${template.name}? Это действие нельзя отменить.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () async {
                  // 1. УДАЛЯЕМ ИЗ ВСЕХ ГРУПП ВСЕХ КАТЕГОРИЙ
                  final updatedCategories = _categories.map((cat) {
                    return cat.copyWith(
                     groups: cat.groups.map((g) => g.copyWith(
                      templateIds: g.templateIds
                        .where((id) => id != template.id)
                        .toList(),
                      )).toList(),
                    );
                  }).toList();

                  // 2. УДАЛЯЕМ САМ ШАБЛОН
                  final templates = await StorageService.loadTemplates();
                  templates.removeWhere((t) => t.id == template.id);

                  // 3. СОХРАНЯЕМ ОБА ИЗМЕНЕНИЯ
                  await Future.wait([
                  StorageService.saveTemplates(templates),
                  StorageService.saveCategories(updatedCategories),
                  ]);

                  if (mounted) {
                    Navigator.pop(context);
                    _loadData(); // перезагружаем данные
                  }
                },
                child: const Text('Удалить'),
              ),
            ],
          ),
    );
  }


  // МЕТОД ГЕНЕРАТОРА
  void _openGenerator() async {
    final newTemplate = await Navigator.push<WorkoutTemplate>(
      context,
      MaterialPageRoute(builder: (_)=> const WorkoutGeneratorScreen()),
    );
    if(newTemplate != null) _loadData();
  }
}