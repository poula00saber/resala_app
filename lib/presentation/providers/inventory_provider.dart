import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/inventory_model.dart';

class InventoryProvider extends ChangeNotifier {
  static const String _storageKey = 'inventory_sections_v1';

  List<InventorySectionModel> _sections = [
    InventorySectionModel(id: 'كلي', name: 'كلي'),
    InventorySectionModel(id: 'تعبئة', name: 'تعبئة'),
    InventorySectionModel(id: 'مخازن', name: 'مخازن'),
    InventorySectionModel(id: 'نضافة', name: 'نضافة'),
  ];

  static const List<String> availableUnits = [
    'كيلو',
    'باوند',
    'قطعة',
    'علبة',
    'كيس',
    'زجاجة',
  ];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  InventoryProvider() {
    _loadFromStorage();
  }

  List<InventorySectionModel> get sections => List.unmodifiable(_sections);

  InventorySectionModel getSection(String sectionId) {
    return _sections.firstWhere((section) => section.id == sectionId);
  }

  InventorySubcategoryModel? getSubcategory(
    String sectionId,
    String subcategoryId,
  ) {
    final section = getSection(sectionId);
    for (final subcategory in section.subcategories) {
      if (subcategory.id == subcategoryId) {
        return subcategory;
      }
    }
    return null;
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedValue = prefs.getString(_storageKey);
      if (storedValue != null && storedValue.isNotEmpty) {
        final decoded = jsonDecode(storedValue) as List<dynamic>;
        _sections = decoded
            .whereType<Map>()
            .map(
              (section) => InventorySectionModel.fromJson(
                Map<String, dynamic>.from(section),
              ),
            )
            .toList();
      }
    } catch (_) {
      // Keep the default in-memory structure if persistence is unavailable.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_sections.map((section) => section.toJson()).toList()),
      );
    } catch (_) {
      // Persistence should never block the UI.
    }
  }

  void addSubcategory(String sectionId, String name) {
    final sectionIndex = _sections.indexWhere(
      (section) => section.id == sectionId,
    );
    if (sectionIndex == -1) return;

    final section = _sections[sectionIndex];
    final updatedSubcategories = [
      ...section.subcategories,
      InventorySubcategoryModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
      ),
    ];

    _sections[sectionIndex] = section.copyWith(
      subcategories: updatedSubcategories,
    );
    notifyListeners();
    unawaited(_persist());
  }

  void addItem({
    required String sectionId,
    required String subcategoryId,
    required String name,
    required String unit,
    required int quantity,
  }) {
    _updateItem(
      sectionId: sectionId,
      subcategoryId: subcategoryId,
      item: InventoryItemModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        unit: unit,
        quantity: quantity,
        history: [
          InventoryHistoryEntry(
            action: 'إضافة أولية',
            quantity: quantity,
            unit: unit,
            note: 'إضافة الصنف لأول مرة',
            createdAt: DateTime.now(),
          ),
        ],
      ),
    );
  }

  void applyAdd({
    required String sectionId,
    required String subcategoryId,
    required String itemId,
    required int quantity,
    required String unit,
  }) {
    _applyChange(
      sectionId: sectionId,
      subcategoryId: subcategoryId,
      itemId: itemId,
      delta: quantity,
      action: 'إضافة',
      unit: unit,
      note: 'إضافة كمية',
    );
  }

  void applyDeduct({
    required String sectionId,
    required String subcategoryId,
    required String itemId,
    required int quantity,
    required String unit,
  }) {
    _applyChange(
      sectionId: sectionId,
      subcategoryId: subcategoryId,
      itemId: itemId,
      delta: -quantity,
      action: 'خصم',
      unit: unit,
      note: 'خصم كمية',
    );
  }

  void applyInventoryCount({
    required String sectionId,
    required String subcategoryId,
    required String itemId,
    required int actualQuantity,
    required String unit,
  }) {
    _updateExistingItem(
      sectionId: sectionId,
      subcategoryId: subcategoryId,
      itemId: itemId,
      updater: (item) {
        final difference = actualQuantity - item.quantity;
        final updatedHistory = [
          ...item.history,
          InventoryHistoryEntry(
            action: 'جرد',
            quantity: difference.abs(),
            unit: unit,
            note: difference == 0
                ? 'لا يوجد فرق'
                : difference > 0
                ? 'زيادة في الجرد بمقدار $difference'
                : 'نقص في الجرد بمقدار ${difference.abs()}',
            createdAt: DateTime.now(),
          ),
        ];

        return item.copyWith(
          unit: unit,
          quantity: actualQuantity,
          history: updatedHistory,
        );
      },
    );
  }

  void _applyChange({
    required String sectionId,
    required String subcategoryId,
    required String itemId,
    required int delta,
    required String action,
    required String unit,
    required String note,
  }) {
    _updateExistingItem(
      sectionId: sectionId,
      subcategoryId: subcategoryId,
      itemId: itemId,
      updater: (item) {
        final updatedQuantity = item.quantity + delta;
        if (updatedQuantity < 0) {
          return item;
        }

        final updatedHistory = [
          ...item.history,
          InventoryHistoryEntry(
            action: action,
            quantity: delta.abs(),
            unit: unit,
            note: note,
            createdAt: DateTime.now(),
          ),
        ];

        return item.copyWith(
          unit: unit,
          quantity: updatedQuantity,
          history: updatedHistory,
        );
      },
    );
  }

  void _updateItem({
    required String sectionId,
    required String subcategoryId,
    required InventoryItemModel item,
  }) {
    final sectionIndex = _sections.indexWhere(
      (section) => section.id == sectionId,
    );
    if (sectionIndex == -1) return;

    final section = _sections[sectionIndex];
    final subIndex = section.subcategories.indexWhere(
      (sub) => sub.id == subcategoryId,
    );
    if (subIndex == -1) return;

    final subcategory = section.subcategories[subIndex];
    final updatedItems = [...subcategory.items, item];
    final updatedSubcategories = [...section.subcategories];
    updatedSubcategories[subIndex] = subcategory.copyWith(items: updatedItems);
    _sections[sectionIndex] = section.copyWith(
      subcategories: updatedSubcategories,
    );
    notifyListeners();
    unawaited(_persist());
  }

  void _updateExistingItem({
    required String sectionId,
    required String subcategoryId,
    required String itemId,
    required InventoryItemModel Function(InventoryItemModel item) updater,
  }) {
    final sectionIndex = _sections.indexWhere(
      (section) => section.id == sectionId,
    );
    if (sectionIndex == -1) return;

    final section = _sections[sectionIndex];
    final subIndex = section.subcategories.indexWhere(
      (sub) => sub.id == subcategoryId,
    );
    if (subIndex == -1) return;

    final subcategory = section.subcategories[subIndex];
    final itemIndex = subcategory.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;

    final updatedItems = [...subcategory.items];
    updatedItems[itemIndex] = updater(updatedItems[itemIndex]);
    final updatedSubcategories = [...section.subcategories];
    updatedSubcategories[subIndex] = subcategory.copyWith(items: updatedItems);
    _sections[sectionIndex] = section.copyWith(
      subcategories: updatedSubcategories,
    );
    notifyListeners();
    unawaited(_persist());
  }

  void ensureDefaultSubcategories(String sectionId) {
    final section = getSection(sectionId);
    if (section.subcategories.isNotEmpty) return;

    addSubcategory(sectionId, 'عام');
  }
}
