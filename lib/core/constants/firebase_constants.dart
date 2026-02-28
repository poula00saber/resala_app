// ============================================
// FILE: lib/core/constants/firebase_constants.dart
// UPDATED: Added 'شبل' level
// ============================================

class FirebaseConstants {
  // Collections
  static const String eventsCollection = 'events';
  static const String volunteersCollection = 'volunteers';
  static const String committeesCollection = 'committees';
  static const String evaluationsCollection = 'evaluations';
  static const String interviewsCollection = 'interviews';

  // Event Types
  static const String typeQafela = 'قافلة';
  static const String typeKarnafal = 'كرنفال';
  static const String typeFamilyDay = 'يوم عائلي';
  static const String typeMeeting = 'اجتماع';
  static const String typeAdministrative = 'اداريات';

  // Meeting Places
  static const String meetingOnline = 'أونلاين';
  static const String meetingOfflineBranch = 'أوفلاين بالفرع';
  static const String meetingOfflineExternal = 'أوفلاين بالخارج';
  static const String promotionRequirementsCollection =
      'promotion_requirements';

  // Administrative Types
  static const List<String> administrativeTypes = [
    'تجهيز',
    'طلبية',
    'جرد',
    'اداريات',
    'صرف',
    'مشتريات',
    'ميديا',
    'استكشاف',
    'متابعة',
    'اتصالات',
    'ورشة فنية',
  ];

  // Volunteer Status
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';

  // Interview Questions
  static const List<String> interviewQuestions = [
    'عرفتنا منين',
    'طريقة التواصل',
    'الهوايات والمهارات',
    'لو اختلفنا في النقاش هندير الحوار ازاي خصوصا لو قدام متطوعين',
    'هتعمل ايه لو اخدت تاسك مش عايز تعمله',
    'لو احنا عندنا ايفينت وحصل تهدير في الوجبات والعدد نقص هتتصرف ازاي',
    'تحب الليدر يتعامل معاك ازاي',
    'هتتعامل مع الناس ازاي او تحفزهم ازاي',
    'تحب تشتغل لوحدك ولا في تيم',
    'ايه الايام المتاحة وكام يوم تقدر تجيهم',
    'ممكن تشتغل حاجة من البيت',
    'هل شاركت في اي عمل تطوعي',
  ];

  // Interview Status
  static const String interviewStatusPending = 'pending';
  static const String interviewStatusPassed = 'passed';
  static const String interviewStatusFailed = 'failed';

  // Evaluation Criteria
  static const Map<String, String> evaluationCriteria = {
    'commitment': 'الالتزام',
    'performance': 'الأداء',
    'teamwork': 'العمل الجماعي',
    'initiative': 'المبادرة',
  };

  // Genders (NEW)
  static const List<String> genders = ['ذكر', 'أنثى'];

  // NEW: Educational/Promotion Levels with two separate paths
  static const List<String> educationalLevels = [
    'شبل', // Under 17 path start
    'شبل مميز', // Under 17 path second level
    'جدد', // 17+ path start
    'تدريب', // 17+ path second level
    'مشروع مسئول', // Both paths converge here
    'مسئول', // Final level
  ];

  // NEW: Educational Levels with Order (for sorting - higher value = higher rank)
  static const Map<String, int> educationalLevelsOrder = {
    'مسئول': 6,
    'مشروع مسئول': 5,
    'تدريب': 4,
    'شبل مميز': 3,
    'شبل': 2,
    'جدد': 1,
    '': 0,
  };

  /// Sort volunteers by degree (descending) then alphabetically by name.
  /// Works with any object that has educationalLevel and name fields.
  static int compareByDegreeAndName(
    String level1,
    String name1,
    String level2,
    String name2,
  ) {
    final order1 = educationalLevelsOrder[level1] ?? 0;
    final order2 = educationalLevelsOrder[level2] ?? 0;
    if (order1 != order2) return order2.compareTo(order1); // Higher rank first
    return name1.compareTo(name2); // Then alphabetical
  }

  // NEW: Promotion Requirements for each level
  static const Map<String, List<String>> promotionRequirements = {
    'شبل': ['مشاركة شهرين', 'انترفيو التسكين', 'التيشرت'],
    'شبل مميز': [
      'فوق سن 17',
      'مشاركة 4 شهور',
      'الميني كامب',
      'انترفيو الاعمدة',
    ],
    'جدد': [
      'مشاركة شهرين',
      'التيشيرت',
      'الاورينتيشن',
      'انترفيو التسكين',
      'الميني كامب',
    ],
    'تدريب': ['انترفيو الاعمدة', 'مشاركة 4 شهور'],
    'مشروع مسئول': ['كامب 48', 'تارجت رسالاوي', 'حفلة التخرج'],
  };

  // Helper method to determine initial educational level based on age
  static String getInitialEducationalLevel(int age) {
    if (age < 17) {
      return 'شبل';
    } else {
      return 'جدد';
    }
  }

  // Helper method to get next level based on current level and age
  static String? getNextLevel(String currentLevel, {int? age}) {
    switch (currentLevel) {
      case 'شبل':
        return 'شبل مميز';
      case 'شبل مميز':
        // Check if volunteer is above 17
        return 'مشروع مسئول';
      case 'جدد':
        return 'تدريب';
      case 'تدريب':
        return 'مشروع مسئول';
      case 'مشروع مسئول':
        return 'مسئول';
      case 'مسئول':
        return null;
      default:
        return null;
    }
  }

  // Field names for Volunteers
  static const String nameField = 'name';
  static const String phoneField = 'phone';
  static const String emailField = 'email';
  static const String addressField = 'address';
  static const String nationalIdField = 'nationalId';
  static const String ageField = 'age';
  static const String committeeIdField = 'committeeId';
  static const String committeeNameField = 'committeeName';
  static const String hasInterviewField = 'hasInterview';
  static const String hasTshirtField = 'hasTshirt';
  static const String isActiveField = 'isActive';
  static const String createdAtField = 'createdAt';
  static const String updatedAtField = 'updatedAt';
  static const String birthDateField = 'birthDate';
  static const String genderField = 'gender';
  static const String educationalLevelField = 'educationalLevel';
  static const String universityField = 'university';
  static const String profileImageField = 'profileImage';
}
