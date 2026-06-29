// ============================================
// FILE: lib/data/models/app_user_model.dart
// Model for application users (not volunteers)
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';

// Sub-permission for nested pages (reports sub-pages, administrative sub-pages)
class SubPermission {
  final String subPageId;
  final String subPageName;
  final bool canAccess;

  SubPermission({
    required this.subPageId,
    required this.subPageName,
    this.canAccess = false,
  });

  factory SubPermission.fromMap(Map<String, dynamic> map) {
    return SubPermission(
      subPageId: map['subPageId'] ?? '',
      subPageName: map['subPageName'] ?? '',
      canAccess: map['canAccess'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subPageId': subPageId,
      'subPageName': subPageName,
      'canAccess': canAccess,
    };
  }

  SubPermission copyWith({
    String? subPageId,
    String? subPageName,
    bool? canAccess,
  }) {
    return SubPermission(
      subPageId: subPageId ?? this.subPageId,
      subPageName: subPageName ?? this.subPageName,
      canAccess: canAccess ?? this.canAccess,
    );
  }
}

class PagePermission {
  final String pageId;
  final String pageName;
  final bool canAccess;
  final bool canAddDelete; // true = can add/delete, false = read only
  final List<SubPermission> subPermissions; // Sub-permissions for nested pages

  PagePermission({
    required this.pageId,
    required this.pageName,
    this.canAccess = false,
    this.canAddDelete = false,
    this.subPermissions = const [],
  });

  factory PagePermission.fromMap(Map<String, dynamic> map) {
    List<SubPermission> subPerms = [];
    if (map['subPermissions'] != null) {
      subPerms = (map['subPermissions'] as List<dynamic>)
          .map((s) => SubPermission.fromMap(s as Map<String, dynamic>))
          .toList();
    }
    return PagePermission(
      pageId: map['pageId'] ?? '',
      pageName: map['pageName'] ?? '',
      canAccess: map['canAccess'] ?? false,
      canAddDelete: map['canAddDelete'] ?? false,
      subPermissions: subPerms,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pageId': pageId,
      'pageName': pageName,
      'canAccess': canAccess,
      'canAddDelete': canAddDelete,
      'subPermissions': subPermissions.map((s) => s.toMap()).toList(),
    };
  }

  PagePermission copyWith({
    String? pageId,
    String? pageName,
    bool? canAccess,
    bool? canAddDelete,
    List<SubPermission>? subPermissions,
  }) {
    return PagePermission(
      pageId: pageId ?? this.pageId,
      pageName: pageName ?? this.pageName,
      canAccess: canAccess ?? this.canAccess,
      canAddDelete: canAddDelete ?? this.canAddDelete,
      subPermissions: subPermissions ?? this.subPermissions,
    );
  }
}

class AppUserModel {
  final String id;
  final String email;
  final String? displayName;
  final bool isAdmin;
  final bool isDeleted;
  final List<PagePermission> permissions;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final DateTime? deletedAt;

  AppUserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.isAdmin = false,
    this.isDeleted = false,
    required this.permissions,
    required this.createdAt,
    this.lastLogin,
    this.deletedAt,
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
      isDeleted: data['isDeleted'] ?? false,
      permissions: permissions,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLogin: data['lastLogin'] != null
          ? (data['lastLogin'] as Timestamp).toDate()
          : null,
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'isAdmin': isAdmin,
      'isDeleted': isDeleted,
      'permissions': permissions.map((p) => p.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
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

  // Check if user can access a specific sub-page
  bool canAccessSubPage(String pageId, String subPageId) {
    if (isAdmin) return true;
    final permission = permissions.firstWhere(
      (p) => p.pageId == pageId,
      orElse: () => PagePermission(pageId: pageId, pageName: ''),
    );
    if (!permission.canAccess) return false;

    final subPermission = permission.subPermissions.firstWhere(
      (s) => s.subPageId == subPageId,
      orElse: () => SubPermission(subPageId: subPageId, subPageName: ''),
    );
    return subPermission.canAccess;
  }

  AppUserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? isAdmin,
    bool? isDeleted,
    List<PagePermission>? permissions,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? deletedAt,
  }) {
    return AppUserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isAdmin: isAdmin ?? this.isAdmin,
      isDeleted: isDeleted ?? this.isDeleted,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      deletedAt: deletedAt ?? this.deletedAt,
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
  static const String inventory = 'inventory';
  static const String qafla = 'qafla';

  // Reports sub-pages
  static const String reportComprehensive = 'report_comprehensive';
  static const String reportFamilyDay = 'report_family_day';
  static const String reportCubs = 'report_cubs';
  static const String reportMeetings = 'report_meetings';
  static const String reportFund = 'report_fund';
  static const String reportMarketing = 'report_marketing';
  static const String reportMonthly = 'report_monthly';
  static const String reportQafla = 'report_qafla';

  // Administrative sub-pages
  static const String adminFund = 'admin_fund';
  static const String adminMarketing = 'admin_marketing';

  // Get default sub-permissions for reports
  static List<SubPermission> getReportsSubPermissions() {
    return [
      SubPermission(
        subPageId: reportComprehensive,
        subPageName: 'الكلي',
        canAccess: false,
      ),
      SubPermission(
        subPageId: reportFamilyDay,
        subPageName: 'اليوم العائلي',
        canAccess: false,
      ),
      SubPermission(
        subPageId: reportCubs,
        subPageName: 'الأشبال',
        canAccess: false,
      ),
      SubPermission(
        subPageId: reportMeetings,
        subPageName: 'الاجتماعات',
        canAccess: false,
      ),
      SubPermission(
        subPageId: reportFund,
        subPageName: 'الصندوق',
        canAccess: false,
      ),
      SubPermission(
        subPageId: reportMarketing,
        subPageName: 'الدعايا',
        canAccess: false,
      ),
      SubPermission(
        subPageId: reportMonthly,
        subPageName: 'الشهري',
        canAccess: false,
      ),
      SubPermission(
        subPageId: reportQafla,
        subPageName: 'القوافل',
        canAccess: false,
      ),
    ];
  }

  // Get default sub-permissions for administrative
  static List<SubPermission> getAdministrativeSubPermissions() {
    return [
      SubPermission(
        subPageId: adminFund,
        subPageName: 'الصندوق',
        canAccess: false,
      ),
      SubPermission(
        subPageId: adminMarketing,
        subPageName: 'الدعايا',
        canAccess: false,
      ),
    ];
  }

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
        subPermissions: getReportsSubPermissions(),
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
        subPermissions: getAdministrativeSubPermissions(),
      ),
      PagePermission(
        pageId: inventory,
        pageName: 'جرد',
        canAccess: false,
        canAddDelete: false,
      ),
      PagePermission(
        pageId: qafla,
        pageName: 'قوافل',
        canAccess: false,
        canAddDelete: false,
      ),
    ];
  }
}
