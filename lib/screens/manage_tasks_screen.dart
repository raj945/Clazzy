import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/time_tracking_provider.dart';
import '../models/task_node.dart';
import '../constants/colors.dart';

class ManageTasksScreen extends StatefulWidget {
  const ManageTasksScreen({super.key});

  @override
  State<ManageTasksScreen> createState() => _ManageTasksScreenState();
}

class _ManageTasksScreenState extends State<ManageTasksScreen> {
  // Base types for stats calculation
  static const List<String> _baseTypes = [
    'DEEP WORK',
    'PERSONAL',
    'WASTED',
    'SLEEP',
    'UNKNOWN',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeTrackerProvider>(context);
    final tasks = provider.tasks
        .where((t) => t.id != TaskNode.unknownId)
        .toList();
    final categories = provider.getCategories();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simple header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage Tasks',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${tasks.length} tasks • ${categories.length} categories',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showManageCategoriesSheet(
                      context,
                      provider,
                      categories,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.folder_outlined,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Task list
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            color: Colors.grey.shade700,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No tasks yet',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap + to add your first task',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) =>
                          _buildTaskTile(provider, tasks[index]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context, provider),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  Widget _buildTaskTile(TimeTrackerProvider provider, TaskNode task) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.red, size: 20),
      ),
      confirmDismiss: (direction) async {
        return await _confirmDeleteSwipe(context, provider, task);
      },
      child: GestureDetector(
        onTap: () => _showEditTaskDialog(context, provider, task),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Color indicator
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: task.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (task.category.isNotEmpty) ...[
                          Text(
                            task.category,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getBaseTypeColor(
                              task.baseType,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.baseType,
                            style: TextStyle(
                              color: _getBaseTypeColor(task.baseType),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Edit hint
              Icon(Icons.chevron_right, color: Colors.grey.shade700, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteSwipe(
    BuildContext context,
    TimeTrackerProvider provider,
    TaskNode task,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Task?',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to delete "${task.name}"?',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTask(task.id);
              Navigator.pop(context, true);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Color _getBaseTypeColor(String baseType) {
    switch (baseType) {
      case 'DEEP WORK':
        return AppColors.accent;
      case 'PERSONAL':
        return Colors.blue;
      case 'WASTED':
        return Colors.purple;
      case 'SLEEP':
        return Colors.teal;
      case 'UNKNOWN':
        return AppColors.unknown;
      default:
        return Colors.grey;
    }
  }

  void _showManageCategoriesSheet(
    BuildContext context,
    TimeTrackerProvider provider,
    List<String> categories,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setDialogState) {
            final currentCategories = provider.getCategories();
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppColors.accent,
                        ),
                        onPressed: () => _showAddCategoryDialog(
                          context,
                          provider,
                          setDialogState,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: currentCategories.length,
                      itemBuilder: (context, index) {
                        final cat = currentCategories[index];
                        final baseType = provider.getCategoryBaseType(cat);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _getBaseTypeColor(baseType),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '→ $baseType',
                                      style: TextStyle(
                                        color: _getBaseTypeColor(baseType),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.grey.shade600,
                                  size: 18,
                                ),
                                onPressed: () {
                                  provider.deleteCategory(cat);
                                  setDialogState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddCategoryDialog(
    BuildContext context,
    TimeTrackerProvider provider,
    StateSetter parentSetState,
  ) {
    final nameController = TextEditingController();
    String selectedBaseType = 'DEEP WORK';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'New Category',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Category Name'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Counts as:',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _baseTypes.map((type) {
                  final isSelected = selectedBaseType == type;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedBaseType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getBaseTypeColor(type).withValues(alpha: 0.2)
                            : Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: _getBaseTypeColor(type))
                            : null,
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: isSelected
                              ? _getBaseTypeColor(type)
                              : Colors.grey.shade400,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  provider.addCategory(
                    nameController.text.toUpperCase(),
                    selectedBaseType,
                  );
                  parentSetState(() {});
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Add',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, TimeTrackerProvider provider) {
    final nameController = TextEditingController();
    final subtitleController = TextEditingController();
    String selectedCategory = '';
    String selectedBaseType = 'DEEP WORK';
    Color selectedColor = Colors.grey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final categories = provider.getCategories();
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Task',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Task Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subtitleController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Subtitle (optional)'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Category',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildCategoryChip(
                        '',
                        selectedCategory,
                        (c) => setDialogState(() {
                          selectedCategory = c;
                        }),
                      ),
                      ...categories.map(
                        (cat) => _buildCategoryChip(
                          cat,
                          selectedCategory,
                          (c) => setDialogState(() {
                            selectedCategory = c;
                            selectedBaseType = provider.getCategoryBaseType(c);
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    selectedCategory.isEmpty
                        ? 'Counts as (for stats)'
                        : 'Counts as (from category)',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _baseTypes.map((type) {
                      final isSelected = selectedBaseType == type;
                      final isDisabled = selectedCategory.isNotEmpty;
                      return GestureDetector(
                        onTap: isDisabled
                            ? null
                            : () =>
                                  setDialogState(() => selectedBaseType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _getBaseTypeColor(type).withValues(alpha: 0.2)
                                : Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(color: _getBaseTypeColor(type))
                                : null,
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isSelected
                                  ? _getBaseTypeColor(type)
                                  : Colors.grey.shade400.withValues(
                                      alpha: isDisabled ? 0.4 : 1,
                                    ),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Color',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  _buildColorPicker(
                    selectedColor,
                    (c) => setDialogState(() => selectedColor = c),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          final baseType = selectedCategory.isNotEmpty
                              ? provider.getCategoryBaseType(selectedCategory)
                              : selectedBaseType;
                          provider.addTask(
                            name: nameController.text,
                            subtitle: subtitleController.text.isEmpty
                                ? null
                                : subtitleController.text,
                            category: selectedCategory,
                            baseType: baseType,
                            colorValue: selectedColor.value,
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ADD TASK',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(
    String cat,
    String selected,
    Function(String) onTap,
  ) {
    final isSelected = selected == cat;
    return GestureDetector(
      onTap: () => onTap(cat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.2)
              : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: AppColors.accent) : null,
        ),
        child: Text(
          cat.isEmpty ? 'NONE' : cat,
          style: TextStyle(
            color: isSelected ? AppColors.accent : Colors.grey.shade400,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker(Color selected, Function(Color) onSelect) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey.shade900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Pick Color',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            content: SizedBox(
              width: 280,
              height: 280,
              child: _ColorPickerWidget(
                initialColor: selected,
                onColorChanged: (color) {
                  onSelect(color);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Tap to pick color',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(
    BuildContext context,
    TimeTrackerProvider provider,
    TaskNode task,
  ) {
    final nameController = TextEditingController(text: task.name);
    final subtitleController = TextEditingController(text: task.subtitle ?? '');
    String selectedCategory = task.category;
    String selectedBaseType = task.baseType;
    Color selectedColor = task.color;
    String? selectedLinkedInputId = task.linkedInputId;

    // Ensure selectedLinkedInputId is valid (input exists) or null
    if (selectedLinkedInputId != null &&
        !provider.learningInputs.any((i) => i.id == selectedLinkedInputId)) {
      selectedLinkedInputId = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final categories = provider.getCategories();
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Task',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Task Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subtitleController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Subtitle (optional)'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Category',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildCategoryChip(
                        '',
                        selectedCategory,
                        (c) => setDialogState(() {
                          selectedCategory = c;
                        }),
                      ),
                      ...categories.map(
                        (cat) => _buildCategoryChip(
                          cat,
                          selectedCategory,
                          (c) => setDialogState(() {
                            selectedCategory = c;
                            selectedBaseType = provider.getCategoryBaseType(c);
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    selectedCategory.isEmpty
                        ? 'Counts as (for stats)'
                        : 'Counts as (from category)',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _baseTypes.map((type) {
                      final isSelected = selectedBaseType == type;
                      final isDisabled = selectedCategory.isNotEmpty;
                      return GestureDetector(
                        onTap: isDisabled
                            ? null
                            : () =>
                                  setDialogState(() => selectedBaseType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _getBaseTypeColor(type).withValues(alpha: 0.2)
                                : Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(color: _getBaseTypeColor(type))
                                : null,
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isSelected
                                  ? _getBaseTypeColor(type)
                                  : Colors.grey.shade400.withValues(
                                      alpha: isDisabled ? 0.4 : 1,
                                    ),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Linked Input Dropdown
                  if (provider.learningInputs.isNotEmpty) ...[
                    const Text(
                      'Link to Knowledge Hub Input',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedLinkedInputId,
                      dropdownColor: Colors.grey.shade900,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Select Input (Optional)'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'None',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ...provider.learningInputs.map((input) {
                          return DropdownMenuItem<String?>(
                            value: input.id,
                            child: Text(
                              input.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) =>
                          setDialogState(() => selectedLinkedInputId = val),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Color',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  _buildColorPicker(
                    selectedColor,
                    (c) => setDialogState(() => selectedColor = c),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          final baseType = selectedCategory.isNotEmpty
                              ? provider.getCategoryBaseType(selectedCategory)
                              : selectedBaseType;
                          provider.updateTask(
                            task.id,
                            name: nameController.text,
                            subtitle: subtitleController.text.isEmpty
                                ? null
                                : subtitleController.text,
                            category: selectedCategory,
                            baseType: baseType,
                            colorValue: selectedColor.value,
                            linkedInputId: selectedLinkedInputId,
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

class _ColorPickerWidget extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorChanged;

  const _ColorPickerWidget({
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<_ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<_ColorPickerWidget> {
  double _hue = 0;
  double _saturation = 1;
  double _brightness = 1;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _brightness = hsv.value;
  }

  Color get _currentColor =>
      HSVColor.fromAHSV(1, _hue, _saturation, _brightness).toColor();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main color area
        Expanded(
          child: GestureDetector(
            onPanUpdate: (details) {
              final box = context.findRenderObject() as RenderBox;
              final localPos = details.localPosition;
              setState(() {
                _saturation = (localPos.dx / box.size.width).clamp(0, 1);
                _brightness = (1 - localPos.dy / (box.size.height - 60)).clamp(
                  0,
                  1,
                );
              });
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white,
                    HSVColor.fromAHSV(1, _hue, 1, 1).toColor(),
                  ],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: _saturation * 248,
                      top: (1 - _brightness) * 180,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          color: _currentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Hue slider
        Container(
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF0000),
                Color(0xFFFFFF00),
                Color(0xFF00FF00),
                Color(0xFF00FFFF),
                Color(0xFF0000FF),
                Color(0xFFFF00FF),
                Color(0xFFFF0000),
              ],
            ),
          ),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 24,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: SliderComponentShape.noOverlay,
              trackShape: const RoundedRectSliderTrackShape(),
              thumbColor: Colors.white,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
            ),
            child: Slider(
              value: _hue,
              min: 0,
              max: 360,
              onChanged: (v) => setState(() => _hue = v),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Confirm button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => widget.onColorChanged(_currentColor),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentColor,
              foregroundColor: _brightness > 0.5 ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'SELECT',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
