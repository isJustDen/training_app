//widgets/app_header.dart

import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget{
  final String title;
  final String subtitle;
  final List<_HeaderAction> actions;
  final double expandedHeight;

  const AppHeader ({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const[],
    this.expandedHeight = 130,
    });

  @override
  Widget build(BuildContext context){
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true, // Остаётся видимым при скролле
      backgroundColor: colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
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
                          title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // КНОПКИ ДЕЙСТВИЙ
                  ...actions.map((actions) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildActionButton(context, actions),
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton( BuildContext context, _HeaderAction action) {
    return Tooltip(
      message: action.tooltip,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(action.icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// МОДЕЛЬ КНОПКИ ДЕЙСТВИЯ
class _HeaderAction {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _HeaderAction({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });
}

// ФАБРИЧНЫЙ МЕТОД для удобного создания кнопок
_HeaderAction headerAction({
  required IconData icon,
  required String tooltip,
  required VoidCallback onTap,
})=> _HeaderAction(icon: icon, onTap: onTap, tooltip: tooltip);