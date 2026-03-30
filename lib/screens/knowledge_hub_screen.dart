import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/time_tracking_provider.dart';
import '../models/learning_input.dart';
import 'package:uuid/uuid.dart';
import '../constants/colors.dart';

class KnowledgeHubScreen extends StatefulWidget {
  const KnowledgeHubScreen({super.key});

  @override
  State<KnowledgeHubScreen> createState() => _KnowledgeHubScreenState();
}

class _KnowledgeHubScreenState extends State<KnowledgeHubScreen> {
  String _searchQuery = '';
  // Filters
  String _statusFilter = 'Active'; // Active, Finished, Archived, All
  final String _typeFilter = 'All';
  // Sorting
  final String _sortBy = 'Recent';

  // Category collapse state
  final Set<String> _collapsedCategories = {};

  // Display mode per category: 'list', 'tree', or 'board'
  final Map<String, String> _categoryDisplayModes = {};

  String _getCategoryDisplayMode(String category) {
    return _categoryDisplayModes[category] ?? 'list'; // Default to list
  }

  void _setCategoryDisplayMode(String category, String mode) {
    setState(() {
      _categoryDisplayModes[category] = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeTrackerProvider>(context);
    final allInputs = provider.learningInputs;

    // Filter Logic
    List<LearningInput> filteredInputs = allInputs.where((input) {
      if (_searchQuery.isNotEmpty &&
          !input.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !(input.description ?? '').toLowerCase().contains(
            _searchQuery.toLowerCase(),
          )) {
        return false;
      }

      if (_typeFilter != 'All' && input.type != _typeFilter) return false;

      // Status Filter
      if (_statusFilter == 'Active') {
        return input.isSaved || input.isInProgress;
      } else if (_statusFilter == 'Finished') {
        return input.isCompleted;
      } else if (_statusFilter == 'Archived') {
        return input.isArchived;
      }
      return true;
    }).toList();

    // Sort by recent first
    filteredInputs.sort((a, b) {
      if (_sortBy == 'Recent') {
        return b.createdAt.compareTo(a.createdAt);
      } else if (_sortBy == 'Status') {
        return a.status.compareTo(b.status);
      } else if (_sortBy == 'Type') {
        return a.type.compareTo(b.type);
      }
      return 0;
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildControlBar(),
            Expanded(
              child: filteredInputs.isEmpty
                  ? _buildEmptyState()
                  : _buildMainContent(filteredInputs, provider),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          onPressed: () => _showInputDetail(context, null),
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, size: 24),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Knowledge Hub',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'LIBRARY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              // Search Field Expanded? No, Icon?
              // Let's keep search below or next to it.
            ],
          ),
          const SizedBox(height: 16),
          // Search Field
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search Library...',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
              filled: true,
              fillColor: Colors.grey.shade900,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          // Status Filter Tabs (no more global view selector)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Active', 'Finished', 'Archived'].map((status) {
                  final isSelected = _statusFilter == status;
                  return GestureDetector(
                    onTap: () => setState(() => _statusFilter = status),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent.withOpacity(0.5)
                              : Colors.grey.shade800,
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.accent
                              : Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    List<LearningInput> inputs,
    TimeTrackerProvider provider,
  ) {
    // Group inputs by type (category)
    final Map<String, List<LearningInput>> groupedInputs = {};
    for (var input in inputs) {
      groupedInputs.putIfAbsent(input.type, () => []).add(input);
    }

    // Sort types alphabetically
    final sortedTypes = groupedInputs.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: sortedTypes.length,
      itemBuilder: (context, index) {
        final type = sortedTypes[index];
        final typeInputs = groupedInputs[type]!;
        final color = _getTypeColor(type);

        return _buildCategorySection(type, typeInputs, provider, color);
      },
    );
  }

  // Build a category section with all its notes
  Widget _buildCategorySection(
    String type,
    List<LearningInput> inputs,
    TimeTrackerProvider provider,
    Color color,
  ) {
    final isCollapsed = _collapsedCategories.contains(type);
    final displayMode = _getCategoryDisplayMode(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isCollapsed) {
                        _collapsedCategories.remove(type);
                      } else {
                        _collapsedCategories.add(type);
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        isCollapsed ? Icons.chevron_right : Icons.expand_more,
                        color: color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Icon(_getTypeIcon(type), color: color, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${inputs.length}',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                // View Mode Switcher
                _buildCategoryViewSwitcher(type, displayMode, color),
                const SizedBox(width: 12),
                // Add button
                GestureDetector(
                  onTap: () =>
                      _showInputDetail(context, null, preselectedType: type),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.add, size: 16, color: color),
                  ),
                ),
                const SizedBox(width: 8),
                // More button
                SizedBox(
                  width: 28,
                  height: 28,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.more_vert, size: 18, color: color),
                    color: Colors.grey.shade900,
                    onSelected: (action) {
                      if (action == 'rename') {
                        _promptRenameCategory(context, provider, type);
                      } else if (action == 'delete') {
                        _promptDeleteCategory(
                          context,
                          provider,
                          type,
                          inputs.length,
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Rename',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(height: 12),
            _buildCategoryContent(type, inputs, provider, displayMode, color),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${date.month}/${date.day}/${date.year.toString().substring(2)}';
  }

  // View switcher for category header
  Widget _buildCategoryViewSwitcher(
    String category,
    String currentMode,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewToggleIconButton(
            category,
            'list',
            Icons.format_list_bulleted,
            currentMode,
            color,
          ),
          _buildViewToggleIconButton(
            category,
            'tree',
            Icons.account_tree_outlined,
            currentMode,
            color,
          ),
          _buildViewToggleIconButton(
            category,
            'board',
            Icons.grid_view_outlined,
            currentMode,
            color,
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleIconButton(
    String category,
    String mode,
    IconData icon,
    String currentMode,
    Color color,
  ) {
    final isSelected = currentMode == mode;
    return GestureDetector(
      onTap: () => _setCategoryDisplayMode(category, mode),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isSelected ? color : Colors.grey.shade600,
        ),
      ),
    );
  }

  // Render content based on selected display mode
  Widget _buildCategoryContent(
    String type,
    List<LearningInput> inputs,
    TimeTrackerProvider provider,
    String displayMode,
    Color color,
  ) {
    if (displayMode == 'tree') {
      return Column(
        children: inputs
            .map((input) => _buildTreeStyleNote(input, provider))
            .toList(),
      );
    } else if (displayMode == 'board') {
      return SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: inputs.length,
          itemBuilder: (context, index) =>
              _buildBoardStyleNote(inputs[index], provider, color),
        ),
      );
    } else {
      return Column(
        children: inputs
            .map((input) => _buildListStyleNote(input, provider))
            .toList(),
      );
    }
  }

  // Board style note card
  Widget _buildBoardStyleNote(
    LearningInput input,
    TimeTrackerProvider provider,
    Color color,
  ) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      child: InkWell(
        onTap: () => _showInputDetail(context, input),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompactStatusBadge(input.status),
              const Spacer(),
              Text(
                input.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(input.createdAt),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // List style note (default)
  Widget _buildListStyleNote(
    LearningInput input,
    TimeTrackerProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showInputDetail(context, input),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade800.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor(input.status),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      input.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: input.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (input.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        input.description!,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              _buildCompactStatusBadge(input.status),
            ],
          ),
        ),
      ),
    );
  }

  // Tree style note (with indent and connector)
  Widget _buildTreeStyleNote(
    LearningInput input,
    TimeTrackerProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _showInputDetail(context, input),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tree connector
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 1,
                      height: 12,
                      color: Colors.grey.shade700,
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getStatusColor(input.status),
                        border: Border.all(color: Colors.grey.shade700),
                      ),
                    ),
                    Expanded(
                      child: Container(width: 1, color: Colors.grey.shade800),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade800.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        input.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: input.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (input.description?.isNotEmpty == true)
                        Text(
                          input.description!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'book':
        return const Color(0xFF4CAF50); // Green
      case 'video':
        return const Color(0xFFFF0000); // Red (YouTube)
      case 'course':
        return const Color(0xFF2196F3); // Blue
      case 'podcast':
        return const Color(0xFF9C27B0); // Purple
      case 'article':
        return const Color(0xFFFF9800); // Orange
      case 'idea':
        return const Color(0xFFFFEB3B); // Yellow
      default:
        return Colors.grey;
    }
  }

  Widget _buildCompactStatusBadge(String status) {
    Color color;
    String label;
    switch (status.toLowerCase()) {
      case 'in_progress':
        color = Colors.blue;
        label = 'In Progress';
        break;
      case 'finished':
      case 'completed':
        color = Colors.green;
        label = 'Done';
        break;
      case 'archived':
        color = Colors.grey;
        label = 'Archived';
        break;
      default:
        color = Colors.orange;
        label = 'Saved';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_progress':
        return Colors.blueAccent;
      case 'finished':
      case 'completed':
        return Colors.greenAccent;
      case 'archived':
        return Colors.grey;
      default:
        return AppColors.accent;
    }
  }

  // --- DETAIL SHEET ---
  void _showInputDetail(
    BuildContext context,
    LearningInput? input, {
    String? preselectedType,
  }) {
    final provider = Provider.of<TimeTrackerProvider>(context, listen: false);
    final isEditing = input != null;

    // Initialize Controllers (Fixes "Done not working" issue)
    final titleController = TextEditingController(text: input?.title ?? '');
    final tagController = TextEditingController(
      text: input?.tags.join(', ') ?? '',
    );
    final sourceController = TextEditingController(text: input?.source ?? '');
    final descController = TextEditingController(
      text: input?.description ?? '',
    );
    final notesController = TextEditingController(text: input?.notes ?? '');

    // Form State
    String type = input?.type ?? preselectedType ?? 'Book';
    String status = input?.status ?? 'saved';
    List<String> relatedIds = List.from(input?.relatedIds ?? []);

    // Show all fields by default for new items, hide for existing items (compact view)
    bool showAllFields = !isEditing;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E), // Slightly lighter than black
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Toolbar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (titleController.text.trim().isEmpty) return;

                            final newTags = tagController.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();

                            // Determine final category string
                            String finalCategory = type.trim();
                            if (finalCategory.isEmpty) finalCategory = 'Book';

                            // Persist custom category if it's new
                            if (!provider.availableInputTypes.contains(
                              finalCategory,
                            )) {
                              await provider.addLearningCategory(finalCategory);
                            }

                            final newInput = LearningInput(
                              id: input?.id ?? const Uuid().v4(),
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                              type: finalCategory,
                              status: status,
                              source: sourceController.text.trim().isEmpty
                                  ? 'Manual'
                                  : sourceController.text.trim(),
                              url: sourceController.text.trim().isEmpty
                                  ? null
                                  : sourceController.text.trim(),
                              tags: newTags,
                              notes: notesController.text.trim(),
                              createdAt: input?.createdAt ?? DateTime.now(),
                              completedAt:
                                  status == 'finished' &&
                                      input?.status != 'finished'
                                  ? DateTime.now()
                                  : input?.completedAt,
                              relatedIds: relatedIds,
                              linkedTaskId: input?.linkedTaskId,
                            );

                            if (isEditing) {
                              await provider.updateLearningInput(newInput);
                            } else {
                              await provider.addLearningInput(newInput);
                            }

                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white10),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      // Add keyboard height to bottom padding so text fields don't get hidden
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        40 + MediaQuery.of(context).viewInsets.bottom,
                      ),
                      children: [
                        // HIERARCHY / BREADCRUMB
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Library',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              Text(
                                type.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // MAIN TITLE
                        TextField(
                          controller: titleController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'What are you learning?',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          maxLines: null,
                        ),

                        // Compact info bar for existing items (when not in edit mode)
                        if (isEditing && !showAllFields) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade800),
                            ),
                            child: Row(
                              children: [
                                // Type badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(type).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getTypeIcon(type),
                                        size: 14,
                                        color: _getTypeColor(type),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        type,
                                        style: TextStyle(
                                          color: _getTypeColor(type),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Status badge
                                _buildCompactStatusBadge(status),
                                const Spacer(),
                                // Edit button
                                TextButton.icon(
                                  onPressed: () =>
                                      setState(() => showAllFields = true),
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: AppColors.accent,
                                  ),
                                  label: const Text(
                                    'Edit Details',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Show editable fields only when showAllFields is true
                        if (showAllFields) ...[
                          // TYPE SELECTOR (Visual)
                          const Text(
                            'CATEGORY',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 90,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                ...[
                                  'Book',
                                  'Video',
                                  'Course',
                                  'Article',
                                  'Podcast',
                                  'Idea',
                                ].map((t) {
                                  final isSelected = type == t;
                                  return GestureDetector(
                                    onTap: () => setState(() => type = t),
                                    child: Container(
                                      width: 80,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.accent.withOpacity(0.1)
                                            : Colors.grey.shade800,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.accent
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _getTypeIcon(t),
                                            color: isSelected
                                                ? AppColors.accent
                                                : Colors.grey.shade400,
                                            size: 28,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            t,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppColors.accent
                                                  : Colors.grey.shade400,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                // Custom Type Button
                                GestureDetector(
                                  onTap: () => setState(() => type = 'Custom'),
                                  child: Container(
                                    width: 80,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: type == 'Custom'
                                          ? AppColors.accent.withOpacity(0.1)
                                          : Colors.grey.shade800,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: type == 'Custom'
                                            ? AppColors.accent
                                            : Colors.grey.shade700,
                                        width: 2,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          color: type == 'Custom'
                                              ? AppColors.accent
                                              : Colors.grey.shade400,
                                          size: 28,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Custom',
                                          style: TextStyle(
                                            color: type == 'Custom'
                                                ? AppColors.accent
                                                : Colors.grey.shade400,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Custom Type Input
                          if (type == 'Custom' ||
                              ![
                                'Book',
                                'Video',
                                'Course',
                                'Article',
                                'Podcast',
                                'Idea',
                              ].contains(type))
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: TextField(
                                controller:
                                    TextEditingController(
                                        text: type == 'Custom' ? '' : type,
                                      )
                                      ..selection = TextSelection.collapsed(
                                        offset: (type == 'Custom' ? '' : type)
                                            .length,
                                      ),
                                onChanged: (v) {
                                  type = v;
                                  setState(() {
                                    // Update local state if needed
                                  });
                                },
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Custom Category Name',
                                  labelStyle: TextStyle(
                                    color: AppColors.accent,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // STATUS SELECTOR
                          const Text(
                            'STATUS',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children:
                                  [
                                    'saved',
                                    'in_progress',
                                    'finished',
                                    'archived',
                                  ].map((s) {
                                    final isSelected = status == s;
                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => status = s),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF333333)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.2),
                                                      blurRadius: 4,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              _formatStatus(s),
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.grey.shade500,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // COLLECTIONS / TAGS
                          Row(
                            children: [
                              Icon(
                                Icons.folder_copy_outlined,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'COLLECTIONS / TAGS',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildStandardTextField(
                            tagController.text, // This is just for initial?
                            (v) {}, // Controller handles text
                            'Physics, Finance, Self-Improvement...',
                            controller: tagController,
                          ),

                          const SizedBox(height: 24),

                          // SOURCE
                          const Text(
                            'SOURCE LINK',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildStandardTextField(
                            sourceController.text,
                            (v) {},
                            'Paste URL or Origin...',
                            isLink: true,
                            controller: sourceController,
                          ),

                          const SizedBox(height: 32),
                        ], // End of showAllFields conditional
                        // EXTENDED DETAILS (Always visible)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'REFLECTIONS & NOTES',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: descController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Why did you save this?',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                maxLines: 3,
                                minLines: 1,
                              ),
                              const Divider(color: Colors.white10, height: 24),
                              TextField(
                                controller: notesController,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Add your summary or key takeaways...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                maxLines: null,
                                minLines: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // RELATIONS (Simple Linker)
                        if (isEditing) ...[
                          const Text(
                            'RELATED',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: relatedIds.map((rid) {
                              final relInput = provider.learningInputs
                                  .firstWhere(
                                    (i) => i.id == rid,
                                    orElse: () => LearningInput(
                                      id: '',
                                      title: 'Unknown',
                                      type: 'Book',
                                      source: '',
                                      createdAt: DateTime.now(),
                                    ),
                                  );
                              if (relInput.id.isEmpty) return const SizedBox();
                              return Chip(
                                label: Text(
                                  relInput.title,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.grey.shade800,
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () =>
                                    setState(() => relatedIds.remove(rid)),
                              );
                            }).toList(),
                          ),
                          TextButton.icon(
                            onPressed: () => _showRelationPicker(
                              context,
                              provider,
                              input,
                              relatedIds,
                              setState,
                            ),
                            icon: const Icon(
                              Icons.add_link,
                              size: 16,
                              color: AppColors.accent,
                            ),
                            label: const Text(
                              'Add Relationship',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 40),
                        if (isEditing)
                          Center(
                            child: TextButton(
                              onPressed: () {
                                provider.deleteLearningInput(input.id);
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Delete Item',
                                style: TextStyle(color: Colors.red.shade400),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showRelationPicker(
    BuildContext context,
    TimeTrackerProvider provider,
    LearningInput current,
    List<String> currentRelated,
    StateSetter setSheetState,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (ctx) {
        final candidates = provider.learningInputs
            .where((i) => i.id != current.id && !currentRelated.contains(i.id))
            .toList();
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Link to...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  final cand = candidates[index];
                  return ListTile(
                    title: Text(
                      cand.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      cand.type,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    onTap: () {
                      setSheetState(() => currentRelated.add(cand.id));
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStandardTextField(
    String initialValue,
    Function(String) onChanged,
    String hint, {
    int? maxLines = 1,
    int? minLines,
    bool isLink = false,
    TextEditingController? controller,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            // If controller is provided, onChanged is optional but good for local updates if needed
            onChanged: controller == null ? onChanged : null,
            maxLines: maxLines,
            minLines: minLines,
            style: TextStyle(
              color: isLink ? Colors.blueAccent : Colors.white,
              fontSize: 13,
              decoration: isLink ? TextDecoration.underline : null,
            ),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey.shade800,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
        ),
        if (isLink)
          GestureDetector(
            onTap: () async {
              final text = controller?.text ?? initialValue;
              if (text.isNotEmpty) {
                final uri = Uri.parse(text);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.open_in_new,
                color: Colors.grey.shade500,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'book':
        return Icons.menu_book;
      case 'video':
        return Icons.play_circle_outline;
      case 'course':
        return Icons.school_outlined;
      case 'podcast':
        return Icons.mic_none_outlined;
      case 'article':
        return Icons.article_outlined;
      case 'idea':
        return Icons.lightbulb_outline;
      default:
        return Icons.bookmark_border;
    }
  }

  String _formatStatus(String s) {
    if (s == 'in_progress') return 'In Progress';
    if (s == 'not_started') return 'Saved';
    return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Your library is empty',
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }

  void _promptRenameCategory(
    BuildContext context,
    TimeTrackerProvider provider,
    String oldName,
  ) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Rename Category',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'New category name',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty &&
                  controller.text.trim() != oldName) {
                await provider.renameLearningCategory(
                  oldName,
                  controller.text.trim(),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text(
              'Rename',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  void _promptDeleteCategory(
    BuildContext context,
    TimeTrackerProvider provider,
    String category,
    int itemCount,
  ) {
    bool deleteItems = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text(
            'Delete Category',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "$category"?',
                style: const TextStyle(color: Colors.grey),
              ),
              if (itemCount > 0) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: deleteItems,
                      activeColor: Colors.red,
                      side: BorderSide(color: Colors.grey.shade500),
                      onChanged: (val) {
                        setState(() => deleteItems = val ?? false);
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Also delete $itemCount items?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!deleteItems)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      '* Items will be moved to "Uncategorized"',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                await provider.deleteLearningCategory(
                  category,
                  deleteItems: deleteItems,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
