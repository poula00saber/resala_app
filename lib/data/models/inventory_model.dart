class InventoryHistoryEntry {
  final String action;
  final int quantity;
  final String unit;
  final String note;
  final DateTime createdAt;

  InventoryHistoryEntry({
    required this.action,
    required this.quantity,
    required this.unit,
    required this.note,
    required this.createdAt,
  });

  factory InventoryHistoryEntry.fromJson(Map<String, dynamic> json) {
    return InventoryHistoryEntry(
      action: json['action']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unit: json['unit']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'quantity': quantity,
      'unit': unit,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class InventoryItemModel {
  final String id;
  final String name;
  final String unit;
  final int quantity;
  final List<InventoryHistoryEntry> history;

  InventoryItemModel({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    this.history = const [],
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      history: (json['history'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (entry) => InventoryHistoryEntry.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'history': history.map((entry) => entry.toJson()).toList(),
    };
  }

  InventoryItemModel copyWith({
    String? id,
    String? name,
    String? unit,
    int? quantity,
    List<InventoryHistoryEntry>? history,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      history: history ?? this.history,
    );
  }
}

class InventorySubcategoryModel {
  final String id;
  final String name;
  final List<InventoryItemModel> items;

  InventorySubcategoryModel({
    required this.id,
    required this.name,
    this.items = const [],
  });

  factory InventorySubcategoryModel.fromJson(Map<String, dynamic> json) {
    return InventorySubcategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                InventoryItemModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  InventorySubcategoryModel copyWith({
    String? id,
    String? name,
    List<InventoryItemModel>? items,
  }) {
    return InventorySubcategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }
}

class InventorySectionModel {
  final String id;
  final String name;
  final List<InventorySubcategoryModel> subcategories;

  InventorySectionModel({
    required this.id,
    required this.name,
    this.subcategories = const [],
  });

  factory InventorySectionModel.fromJson(Map<String, dynamic> json) {
    return InventorySectionModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      subcategories: (json['subcategories'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (subcategory) => InventorySubcategoryModel.fromJson(
              Map<String, dynamic>.from(subcategory),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subcategories': subcategories
          .map((subcategory) => subcategory.toJson())
          .toList(),
    };
  }

  InventorySectionModel copyWith({
    String? id,
    String? name,
    List<InventorySubcategoryModel>? subcategories,
  }) {
    return InventorySectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      subcategories: subcategories ?? this.subcategories,
    );
  }
}
