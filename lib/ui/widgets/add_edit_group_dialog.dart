import 'package:flutter/material.dart';
import '../../config/app_constants.dart';
import '../../data/models/person_model.dart';
import '../../data/models/split_group_model.dart';
import '../view_models/cash_book_view_model.dart';
import 'add_edit_person_dialog.dart';

class AddEditGroupDialog extends StatefulWidget {
  final CashBookViewModel viewModel;
  final SplitGroupModel? initialGroup;

  const AddEditGroupDialog({
    super.key,
    required this.viewModel,
    this.initialGroup,
  });

  static Future<void> show(
    BuildContext context, {
    required CashBookViewModel viewModel,
    SplitGroupModel? initialGroup,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AddEditGroupDialog(
        viewModel: viewModel,
        initialGroup: initialGroup,
      ),
    );
  }

  @override
  State<AddEditGroupDialog> createState() => _AddEditGroupDialogState();
}

class _AddEditGroupDialogState extends State<AddEditGroupDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _searchController;
  final ScrollController _iconScrollController = ScrollController();
  String _searchQuery = '';
  late int _selectedColor;
  late IconData _selectedIcon;
  late Set<String> _selectedMemberIds;

  final List<int> _colorPalette = AppConstants.groupColorPalette;
  final List<IconData> _iconList = AppConstants.groupIcons;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialGroup?.name ?? '');
    _descController = TextEditingController(text: widget.initialGroup?.description ?? '');
    _searchController = TextEditingController();
    _selectedColor = widget.initialGroup?.colorValue ?? _colorPalette[0];
    _selectedIcon = widget.initialGroup != null ? widget.initialGroup!.icon : _iconList[0];

    final currentUserId = widget.viewModel.currentUser.id;
    if (widget.initialGroup != null) {
      _selectedMemberIds = Set.from(widget.initialGroup!.memberIds);
    } else {
      // Default to currentUser only
      _selectedMemberIds = {currentUserId};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    _iconScrollController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedMemberIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 1 friend to the group')),
      );
      return;
    }

    final isEditing = widget.initialGroup != null;
    final group = SplitGroupModel(
      id: widget.initialGroup?.id ?? 'group_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      iconCodePoint: _selectedIcon.codePoint,
      colorValue: _selectedColor,
      memberIds: _selectedMemberIds.toList(),
      createdAt: widget.initialGroup?.createdAt ?? DateTime.now(),
    );

    if (isEditing) {
      widget.viewModel.updateGroup(group);
    } else {
      widget.viewModel.addGroup(group);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.initialGroup != null;
    final currentUserId = widget.viewModel.currentUser.id;

    // Filter unselected friends (excluding current user and already selected members)
    final query = _searchQuery.trim().toLowerCase();
    final isSearching = query.isNotEmpty;

    final unselectedFriends = widget.viewModel.people.where((p) {
      return !p.isCurrentUser && !_selectedMemberIds.contains(p.id);
    }).toList();

    final filteredFriends = !isSearching
        ? <PersonModel>[]
        : unselectedFriends.where((p) {
            final nameMatch = p.name.toLowerCase().contains(query);
            final phoneMatch = p.phoneNumber?.toLowerCase().contains(query) ?? false;
            return nameMatch || phoneMatch;
          }).toList();

    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      actionsOverflowButtonSpacing: 8,
      actionsOverflowDirection: VerticalDirection.down,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(_selectedColor).withValues(alpha: 0.15),
              border: Border.all(color: Color(_selectedColor).withValues(alpha: 0.3)),
            ),
            child: Icon(
              isEditing ? Icons.edit_rounded : Icons.groups_rounded,
              color: Color(_selectedColor),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEditing ? 'Edit Group' : 'Create New Group',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Group Avatar Preview
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      color: Color(_selectedColor),
                      child: Icon(
                        _selectedIcon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.trim().isNotEmpty
                                ? _nameController.text.trim()
                                : (isEditing ? 'Group' : 'New Group'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(_selectedColor),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_selectedMemberIds.length} members selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Group Name Input
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'e.g. Goa Trip, Flat 204',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  prefixIcon: Icon(Icons.groups_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Description Input
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g. Travel and food expenses',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Icon Picker
              Text('Choose Group Icon', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 130),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Scrollbar(
                  controller: _iconScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _iconScrollController,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _iconList.map((iconData) {
                        final isSelected = _selectedIcon.codePoint == iconData.codePoint;
                        return InkWell(
                          onTap: () => setState(() => _selectedIcon = iconData),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? Color(_selectedColor).withValues(alpha: 0.15) : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? Color(_selectedColor)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              iconData,
                              color: isSelected ? Color(_selectedColor) : theme.colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Color Palette Picker
              Text('Choose Color Theme', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorPalette.map((colVal) {
                  final isSelected = _selectedColor == colVal;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = colVal),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(colVal),
                        border: isSelected
                            ? Border.all(color: isDark ? Colors.white : Colors.black87, width: 3)
                            : Border.all(
                                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                width: 1,
                              ),
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Selected Members Section
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Group Members (${_selectedMemberIds.length})',
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Min 2 members',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Chips of currently selected members
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedMemberIds.map((mId) {
                  final person = widget.viewModel.getPersonById(mId);
                  if (person == null) return const SizedBox();
                  final isYou = person.id == currentUserId;

                  return InputChip(
                    avatar: Container(
                      width: 20,
                      height: 20,
                      color: person.color,
                      alignment: Alignment.center,
                      child: Text(
                        person.initials,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    label: Text(isYou ? 'You' : person.name),
                    onDeleted: isYou
                        ? null
                        : () {
                            setState(() {
                              _selectedMemberIds.remove(person.id);
                            });
                          },
                    deleteIcon: isYou ? null : const Icon(Icons.close, size: 16),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Add Friends Section Header & Quick Create
              Row(
                children: [
                  Icon(Icons.person_add_alt_1_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Add Friends',
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      foregroundColor: theme.colorScheme.primary,
                    ),
                    onPressed: () async {
                      final newFriend = await AddEditPersonDialog.show(context, viewModel: widget.viewModel);
                      if (newFriend != null && mounted) {
                        setState(() {
                          _selectedMemberIds.add(newFriend.id);
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      }
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 15),
                    label: const Text('+ New Friend', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Search Friends Input
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Friends',
                  hintText: 'Type friend name or phone...',
                  isDense: true,
                  prefixIcon: const Icon(Icons.person_search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),

              // Filtered Friends List Container (only shown when searching)
              if (isSearching) ...[
                const SizedBox(height: 8),
                Material(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: filteredFriends.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_search_rounded, size: 32, color: Colors.grey.shade400),
                                const SizedBox(height: 6),
                                Text(
                                  unselectedFriends.isEmpty
                                      ? 'All friends are already in this group'
                                      : 'No friend matching "$_searchQuery"',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () async {
                                    final newFriend = await AddEditPersonDialog.show(context, viewModel: widget.viewModel);
                                    if (newFriend != null && mounted) {
                                      setState(() {
                                        _selectedMemberIds.add(newFriend.id);
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                                  label: const Text('Add New Friend'),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: filteredFriends.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final friend = filteredFriends[idx];

                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  color: friend.color,
                                  alignment: Alignment.center,
                                  child: Text(
                                    friend.initials,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  friend.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: friend.phoneNumber != null
                                    ? Text(
                                        friend.phoneNumber!,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                    )
                                    : null,
                                trailing: FilledButton.tonal(
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedMemberIds.add(friend.id);
                                    });
                                  },
                                  child: const Text('Add', style: TextStyle(fontSize: 12)),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedMemberIds.add(friend.id);
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (isEditing)
          TextButton.icon(
            onPressed: () async {
              final nav = Navigator.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  title: const Text('Delete Group?'),
                  content: Text('Delete "${widget.initialGroup!.name}"? Group expenses will also be removed.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await widget.viewModel.deleteGroup(widget.initialGroup!.id);
                nav.pop();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: Text(isEditing ? 'Save' : 'Create Group'),
        ),
      ],
    );
  }
}
