import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../themes/app_theme.dart';
import '../../widgets/app_ui_widgets.dart';
import '../../widgets/whale_loading.dart';
import '../../providers/inventory_provider.dart';
import '../../../data/models/inventory_model.dart';

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

        final section = inventoryProvider.getSection(sectionId);
        final rows = _buildRows(context, section, inventoryProvider);

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
                              section.name,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          Text(
                            '${section.subcategories.length} فئة فرعية',
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
                    child: rows.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد بيانات بعد',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: AppTheme.secondary,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: WidgetStatePropertyAll(
                                  AppTheme.primary.withOpacity(0.12),
                                ),
                                columns: const [
                                  DataColumn(label: Text('القسم')),
                                  DataColumn(label: Text('الصنف')),
                                  DataColumn(label: Text('الوحدة')),
                                  DataColumn(label: Text('الكمية')),
                                  DataColumn(label: Text('إضافة')),
                                  DataColumn(label: Text('خصم')),
                                  DataColumn(label: Text('جرد')),
                                  DataColumn(label: Text('السجل')),
                                ],
                                rows: rows,
                              ),
                            ),
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

  List<DataRow> _buildRows(
    BuildContext context,
    InventorySectionModel section,
    InventoryProvider provider,
  ) {
    final result = <DataRow>[];

    for (final subcategory in section.subcategories) {
      for (final item in subcategory.items) {
        final latestHistory = item.history.isNotEmpty
            ? item.history.last
            : null;
        result.add(
          DataRow(
            color: WidgetStatePropertyAll(
              item.history.length == 1
                  ? AppTheme.primary.withOpacity(0.06)
                  : Colors.transparent,
            ),
            cells: [
              DataCell(Text(subcategory.name)),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.name),
                    if (latestHistory != null)
                      Text(
                        '${latestHistory.action}: ${latestHistory.quantity} ${latestHistory.unit}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: AppTheme.secondary,
                        ),
                      ),
                  ],
                ),
              ),
              DataCell(Text(item.unit)),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.quantity.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'سجل ${item.history.length}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                IconButton(
                  tooltip: 'إضافة',
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => _showItemActionDialog(
                    context,
                    provider,
                    section.id,
                    subcategory.id,
                    item,
                    'إضافة',
                  ),
                ),
              ),
              DataCell(
                IconButton(
                  tooltip: 'خصم',
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _showItemActionDialog(
                    context,
                    provider,
                    section.id,
                    subcategory.id,
                    item,
                    'خصم',
                  ),
                ),
              ),
              DataCell(
                IconButton(
                  tooltip: 'جرد',
                  icon: const Icon(Icons.fact_check, color: AppTheme.primary),
                  onPressed: () => _showItemActionDialog(
                    context,
                    provider,
                    section.id,
                    subcategory.id,
                    item,
                    'جرد',
                  ),
                ),
              ),
              DataCell(
                IconButton(
                  tooltip: 'عرض السجل',
                  icon: const Icon(Icons.history, color: AppTheme.secondary),
                  onPressed: () => _showItemHistoryDialog(context, item),
                ),
              ),
            ],
          ),
        );
      }
    }

    return result;
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
              provider.addSubcategory(sectionId, name);
              Navigator.pop(dialogContext);
            },
            child: const Text('إضافة', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddItemDialog(
    BuildContext context,
    InventoryProvider provider,
  ) async {
    if (provider.getSection(sectionId).subcategories.isEmpty) {
      provider.addSubcategory(sectionId, 'عام');
    }

    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    String selectedSubcategoryId = provider
        .getSection(sectionId)
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
                    value: selectedSubcategoryId,
                    decoration: const InputDecoration(
                      labelText: 'القسم الفرعي',
                    ),
                    items: provider
                        .getSection(sectionId)
                        .subcategories
                        .map(
                          (subcategory) => DropdownMenuItem(
                            value: subcategory.id,
                            child: Text(subcategory.name),
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
                    value: selectedUnit,
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
                    sectionId: sectionId,
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
              value: selectedUnit,
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

  Future<void> _showItemHistoryDialog(
    BuildContext context,
    InventoryItemModel item,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'سجل ${item.name}',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        content: SizedBox(
          width: 380,
          child: item.history.isEmpty
              ? const Text(
                  'لا يوجد سجل بعد',
                  style: TextStyle(fontFamily: 'Cairo'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: item.history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = item.history[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.05),
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
