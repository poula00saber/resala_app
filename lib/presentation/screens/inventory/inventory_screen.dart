import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../themes/app_theme.dart';
import '../../widgets/app_ui_widgets.dart';
import '../../widgets/whale_loading.dart';
import '../../providers/inventory_provider.dart';
import '../../../data/models/inventory_model.dart';
import '../../../services/excel_export_helper.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  static const List<String> _tabs = ['كلي', 'تعبئة', 'مخازن', 'نضافة'];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: _tabs.length,
        child: Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            elevation: 0,
            title: const Text(
              'جرد',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textDark),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Consumer<InventoryProvider>(
                builder: (context, inventoryProvider, _) {
                  return IconButton(
                    icon: const Icon(
                      Icons.file_download,
                      color: AppTheme.primary,
                    ),
                    tooltip: 'تصدير إلى Excel',
                    onPressed: () {
                      final entries = inventoryProvider.getDisplayEntries(
                        'كلي',
                      );
                      if (entries.isEmpty) return;
                      ExcelExportHelper.exportInventoryToExcel(
                        displayEntries: entries,
                        sections: inventoryProvider.sections,
                      );
                    },
                  );
                },
              ),
            ],
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'كلي'),
                Tab(text: 'تعبئة'),
                Tab(text: 'مخازن'),
                Tab(text: 'نضافة'),
              ],
            ),
          ),
          body: TabBarView(
            children: _tabs
                .map((tabName) => _InventorySectionView(sectionId: tabName))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _InventorySectionView extends StatelessWidget {
  final String sectionId;

  const _InventorySectionView({required this.sectionId});

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, _) {
        if (inventoryProvider.isLoading) {
          return const Center(child: WhaleLoading());
        }

        final displayEntries = inventoryProvider.getDisplayEntries(sectionId);
        final section = inventoryProvider.getSection(sectionId);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              sectionId == 'كلي' ? 'كلي' : section.name,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          Text(
                            sectionId == 'كلي'
                                ? '${inventoryProvider.sections.where((entry) => entry.id != 'كلي').fold<int>(0, (sum, current) => sum + current.subcategories.length)} فئة فرعية'
                                : '${section.subcategories.length} فئة فرعية',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'أضف فئات وأصناف ثم استخدم أزرار الإضافة أو الخصم أو الجرد لكل صنف.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppPrimaryActionButton(
                              label: 'إضافة قسم فرعي',
                              onPressed: () => _showAddSubcategoryDialog(
                                context,
                                inventoryProvider,
                              ),
                              textStyle: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppPrimaryActionButton(
                              label: 'إضافة صنف',
                              onPressed: () => _showAddItemDialog(
                                context,
                                inventoryProvider,
                              ),
                              textStyle: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: displayEntries.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد بيانات بعد',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: AppTheme.secondary,
                              ),
                            ),
                          )
                        : _buildCustomTable(
                            context,
                            displayEntries,
                            inventoryProvider,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomTable(
    BuildContext context,
    List<InventoryDisplayEntry> displayEntries,
    InventoryProvider provider,
  ) {
    const columnLabels = [
      'القسم',
      'الصنف',
      'الوحدة',
      'الكمية',
      'إضافة',
      'خصم',
      'جرد',
      'السجل',
      'تعديل',
      'حذف',
    ];
    const columnWidths = [
      60.0,
      140.0,
      60.0,
      70.0,
      50.0,
      50.0,
      50.0,
      50.0,
      50.0,
      50.0,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Container(
                color: AppTheme.primary.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Row(
                  children: List.generate(columnLabels.length, (i) {
                    return SizedBox(
                      width: columnWidths[i],
                      child: Text(
                        columnLabels[i],
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }),
                ),
              ),
              // Data rows
              ...List.generate(displayEntries.length, (index) {
                final entry = displayEntries[index];
                final item = entry.item;
                final latestHistory = item.history.isNotEmpty
                    ? item.history.last
                    : null;
                final isNew = item.history.length == 1;

                return Container(
                  decoration: BoxDecoration(
                    color: isNew
                        ? AppTheme.primary.withValues(alpha: 0.06)
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // القسم
                      SizedBox(
                        width: columnWidths[0],
                        child: Text(
                          entry.sectionName,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // الصنف
                      SizedBox(
                        width: columnWidths[1],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              entry.subcategoryName,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (latestHistory != null)
                              Text(
                                '${latestHistory.action}: ${latestHistory.quantity} ${latestHistory.unit}',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10,
                                  color: AppTheme.secondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),
                      // الوحدة
                      SizedBox(
                        width: columnWidths[2],
                        child: Text(
                          item.unit,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // الكمية
                      SizedBox(
                        width: columnWidths[3],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.quantity.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'سجل ${item.history.length}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                color: AppTheme.secondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      // إضافة
                      SizedBox(
                        width: columnWidths[4],
                        child: _buildActionIcon(
                          Icons.add_circle,
                          Colors.green,
                          () => _showItemActionDialog(
                            context,
                            provider,
                            entry.sectionId,
                            entry.subcategoryId,
                            item,
                            'إضافة',
                          ),
                        ),
                      ),
                      // خصم
                      SizedBox(
                        width: columnWidths[5],
                        child: _buildActionIcon(
                          Icons.remove_circle,
                          Colors.red,
                          () => _showItemActionDialog(
                            context,
                            provider,
                            entry.sectionId,
                            entry.subcategoryId,
                            item,
                            'خصم',
                          ),
                        ),
                      ),
                      // جرد
                      SizedBox(
                        width: columnWidths[6],
                        child: _buildActionIcon(
                          Icons.fact_check,
                          AppTheme.primary,
                          () => _showItemActionDialog(
                            context,
                            provider,
                            entry.sectionId,
                            entry.subcategoryId,
                            item,
                            'جرد',
                          ),
                        ),
                      ),
                      // السجل
                      SizedBox(
                        width: columnWidths[7],
                        child: _buildActionIcon(
                          Icons.history,
                          AppTheme.secondary,
                          () => _showItemHistoryDialog(context, item),
                        ),
                      ),
                      // تعديل
                      SizedBox(
                        width: columnWidths[8],
                        child: _buildActionIcon(
                          Icons.edit,
                          Colors.orange,
                          () => _showEditItemDialog(
                            context,
                            provider,
                            entry.sectionId,
                            entry.subcategoryId,
                            item,
                          ),
                        ),
                      ),
                      // حذف
                      SizedBox(
                        width: columnWidths[9],
                        child: _buildActionIcon(
                          Icons.delete_outline,
                          Colors.red,
                          () => _showDeleteItemDialog(
                            context,
                            provider,
                            entry.sectionId,
                            entry.subcategoryId,
                            item,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onPressed) {
    return Center(
      child: IconButton(
        icon: Icon(icon, color: color, size: 22),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  String _resolveTargetSectionId(
    String requestedSectionId,
    InventoryProvider provider,
  ) {
    if (requestedSectionId != 'كلي') {
      return requestedSectionId;
    }

    return provider.sections
        .firstWhere(
          (section) => section.id != 'كلي',
          orElse: () => provider.sections.first,
        )
        .id;
  }

  Future<void> _showAddSubcategoryDialog(
    BuildContext context,
    InventoryProvider provider,
  ) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'إضافة قسم فرعي',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(labelText: 'اسم القسم الفرعي'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              provider.addSubcategory(
                _resolveTargetSectionId(sectionId, provider),
                name,
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('إضافة', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditSubcategoryDialog(
    BuildContext context,
    InventoryProvider provider,
    String sectionId,
    InventorySubcategoryModel subcategory,
  ) async {
    final controller = TextEditingController(text: subcategory.name);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'تعديل القسم الفرعي',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(labelText: 'اسم القسم الفرعي'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateSubcategoryName(
                sectionId: sectionId,
                subcategoryId: subcategory.id,
                newName: controller.text,
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddItemDialog(
    BuildContext context,
    InventoryProvider provider,
  ) async {
    final targetSectionId = _resolveTargetSectionId(sectionId, provider);
    if (provider.getSection(targetSectionId).subcategories.isEmpty) {
      provider.addSubcategory(targetSectionId, 'عام');
    }

    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    String selectedSubcategoryId = provider
        .getSection(targetSectionId)
        .subcategories
        .first
        .id;
    String selectedUnit = InventoryProvider.availableUnits.first;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text(
              'إضافة صنف',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedSubcategoryId,
                    decoration: const InputDecoration(
                      labelText: 'القسم الفرعي',
                    ),
                    items: provider
                        .getSection(targetSectionId)
                        .subcategories
                        .map(
                          (subcategory) => DropdownMenuItem(
                            value: subcategory.id,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onLongPress: () {
                                // Allow renaming the chosen subcategory directly from the dropdown list.
                                _showEditSubcategoryDialog(
                                  dialogContext,
                                  provider,
                                  targetSectionId,
                                  subcategory,
                                );
                              },
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(subcategory.name),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedSubcategoryId = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(labelText: 'اسم الصنف'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantityController,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'الكمية'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedUnit,
                    decoration: const InputDecoration(labelText: 'الوحدة'),
                    items: InventoryProvider.availableUnits
                        .map(
                          (unit) =>
                              DropdownMenuItem(value: unit, child: Text(unit)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedUnit = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final quantity =
                      int.tryParse(quantityController.text.trim()) ?? 0;
                  if (name.isEmpty || quantity <= 0) return;

                  provider.addItem(
                    sectionId: targetSectionId,
                    subcategoryId: selectedSubcategoryId,
                    name: name,
                    unit: selectedUnit,
                    quantity: quantity,
                  );
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'إضافة',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showItemActionDialog(
    BuildContext context,
    InventoryProvider provider,
    String sectionId,
    String subcategoryId,
    InventoryItemModel item,
    String action,
  ) async {
    final quantityController = TextEditingController(text: '1');
    String selectedUnit = item.unit;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '$action - ${item.name}',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الكمية'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedUnit,
              decoration: const InputDecoration(labelText: 'الوحدة'),
              items: InventoryProvider.availableUnits
                  .map(
                    (unit) => DropdownMenuItem(value: unit, child: Text(unit)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                selectedUnit = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity =
                  int.tryParse(quantityController.text.trim()) ?? 0;
              if (quantity <= 0) return;

              if (action == 'إضافة') {
                provider.applyAdd(
                  sectionId: sectionId,
                  subcategoryId: subcategoryId,
                  itemId: item.id,
                  quantity: quantity,
                  unit: selectedUnit,
                );
              } else if (action == 'خصم') {
                provider.applyDeduct(
                  sectionId: sectionId,
                  subcategoryId: subcategoryId,
                  itemId: item.id,
                  quantity: quantity,
                  unit: selectedUnit,
                );
              } else {
                provider.applyInventoryCount(
                  sectionId: sectionId,
                  subcategoryId: subcategoryId,
                  itemId: item.id,
                  actualQuantity: quantity,
                  unit: selectedUnit,
                );
              }

              Navigator.pop(dialogContext);
            },
            child: Text(action, style: const TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditItemDialog(
    BuildContext context,
    InventoryProvider provider,
    String sectionId,
    String subcategoryId,
    InventoryItemModel item,
  ) async {
    final nameController = TextEditingController(text: item.name);
    String selectedUnit = item.unit;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              'تعديل ${item.name}',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'اسم الصنف'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedUnit,
                  decoration: const InputDecoration(labelText: 'الوحدة'),
                  items: InventoryProvider.availableUnits
                      .map(
                        (unit) =>
                            DropdownMenuItem(value: unit, child: Text(unit)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selectedUnit = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final newName = nameController.text.trim();
                  if (newName.isEmpty) return;
                  provider.updateItem(
                    sectionId: sectionId,
                    subcategoryId: subcategoryId,
                    itemId: item.id,
                    newName: newName,
                    newUnit: selectedUnit,
                  );
                  Navigator.pop(dialogContext);
                },
                child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeleteItemDialog(
    BuildContext context,
    InventoryProvider provider,
    String sectionId,
    String subcategoryId,
    InventoryItemModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الصنف', style: TextStyle(fontFamily: 'Cairo')),
        content: Text(
          'هل تريد حذف ${item.name} نهائياً؟',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      provider.deleteItem(
        sectionId: sectionId,
        subcategoryId: subcategoryId,
        itemId: item.id,
      );
    }
  }

  List<InventoryHistoryEntry> _getVisibleHistory(InventoryItemModel item) {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month - 4, now.day);
    final recentEntries = item.history
        .where((entry) => !entry.createdAt.isBefore(cutoff))
        .toList();

    if (recentEntries.isNotEmpty) {
      return recentEntries;
    }

    if (item.history.length <= 4) {
      return item.history;
    }

    return item.history.sublist(item.history.length - 4);
  }

  Future<void> _showItemHistoryDialog(
    BuildContext context,
    InventoryItemModel item,
  ) async {
    final visibleHistory = _getVisibleHistory(item);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'سجل ${item.name}',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        content: SizedBox(
          width: 380,
          child: visibleHistory.isEmpty
              ? const Text(
                  'لا يوجد سجل بعد',
                  style: TextStyle(fontFamily: 'Cairo'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: visibleHistory.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = visibleHistory[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.action,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${entry.quantity} ${entry.unit}',
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.note,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.createdAt.toString().substring(0, 19),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
