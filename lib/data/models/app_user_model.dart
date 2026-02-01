// ============================================
// FILE: lib/data/models/app_user_model.dart
// Model for application users (not volunteers)
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';

class PagePermission {
  final String pageId;
  final String pageName;
  final bool canAccess;
  final bool canAddDelete; // true = can add/delete, false = read only

  PagePermission({
    required this.pageId,
    required this.pageName,
    this.canAccess = false,
    this.canAddDelete = false,
  });

  factory PagePermission.fromMap(Map<String, dynamic> map) {
    return PagePermission(
      pageId: map['pageId'] ?? '',
      pageName: map['pageName'] ?? '',
      canAccess: map['canAccess'] ?? false,
      canAddDelete: map['canAddDelete'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pageId': pageId,
      'pageName': pageName,
      'canAccess': canAccess,
      'canAddDelete': canAddDelete,
    };
  }

  PagePermission copyWith({
    String? pageId,
    String? pageName,
    bool? canAccess,
    bool? canAddDelete,
  }) {
    return PagePermission(
      pageId: pageId ?? this.pageId,
      pageName: pageName ?? this.pageName,
      canAccess: canAccess ?? this.canAccess,
      canAddDelete: canAddDelete ?? this.canAddDelete,
    );
  }
}

class AppUserModel {
  final String id;
  final String email;
  final String? displayName;
  final bool isAdmin;
  final List<PagePermission> permissions;
  final DateTime createdAt;
  final DateTime? lastLogin;

  AppUserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.isAdmin = false,
    required this.permissions,
    required this.createdAt,
    this.lastLogin,
  });

  factory AppUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<PagePermission> permissions = [];
    if (data['permissions'] != null) {
      permissions = (data['permissions'] as List<dynamic>)
          .map((p) => PagePermission.fromMap(p as Map<String, dynamic>))
          .toList();
    }

    return AppUserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      isAdmin: data['isAdmin'] ?? false,
      permissions: permissions,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLogin: data['lastLogin'] != null
          ? (data['lastLogin'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'isAdmin': isAdmin,
      'permissions': permissions.map((p) => p.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  // Check if user can access a specific page
  bool canAccessPage(String pageId) {
    if (isAdmin) return true;
    final permission = permissions.firstWhere(
      (p) => p.pageId == pageId,
      orElse: () => PagePermission(pageId: pageId, pageName: ''),
    );
    return permission.canAccess;
  }

  // Check if user can add/delete on a specific page
  bool canAddDeleteOnPage(String pageId) {
    if (isAdmin) return true;
    final permission = permissions.firstWhere(
      (p) => p.pageId == pageId,
      orElse: () => PagePermission(pageId: pageId, pageName: ''),
    );
    return permission.canAccess && permission.canAddDelete;
  }

  AppUserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? isAdmin,
    List<PagePermission>? permissions,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return AppUserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isAdmin: isAdmin ?? this.isAdmin,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

// Available pages in the app with their IDs
class AppPages {
  static const String profiles = 'profiles';
  static const String reports = 'reports';
  static const String events = 'events';
  static const String evaluations = 'evaluations';
  static const String contacts = 'contacts';
  static const String interviews = 'interviews';
  static const String promotions = 'promotions';
  static const String committees = 'committees';
  static const String administrative = 'administrative';

  static List<PagePermission> getAllPagesDefault() {
    return [
      PagePermission(
        pageId: profiles,
        pageName: 'بروفايلات',
        canAccess: false,
        canAddDelete: false,
      ),
      PagePermission(
        pageId: reports,
        pageName: 'تقارير',
        canAccess: false,
        canAddDelete: false,
      ),
      PagePermission(
        pageId: events,
        pageName: 'الأحداث',
        canAccess: false,
        canAddDelete: false,
      ),
      PagePermission(
        pageId: evaluations,
        pageName: 'تقييمات',
        canAccess: false,
        canAddDelete: false,
      ),
      PagePermission(
        pageId: contacts,
        pageName: 'اتصالات',
        canAccess: false,
        canAddDelete: false,
      ),
      PagePermission(
        pageId: interviews,
        pageName: 'مقابلات',
        canAccess: false,
        canAddDelete: false,
      ),
      PagePermission(
        pageId: promotions,
        pageName: 'ترقيات',
        canAccess: false,
        canAddDelete: false,
      ),
      PagePermission(
        pageId: committees,
        pageName: 'الهيكل',
        canAccess: false,
        canAddDelete: false,
      ),
      PagePermission(
        pageId: administrative,
        pageName: 'اداريات',
        canAccess: false,
        canAddDelete: false,
      ),
    ];
  }
}
