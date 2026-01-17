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
    'اجتماع تخطيطي',
    'مراجعة مالية',
    'تقييم أداء',
    'اجتماع طوارئ',
    'اجتماع دوري',
    'مراجعة مشاريع',
    'تدريب إداري',
    'اجتماع فريق',
    'اجتماع مجلس إدارة',
    'اجتماع لجنة',
  ];

  // Volunteer Status
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';

  // Evaluation Criteria
  static const Map<String, String> evaluationCriteria = {
    'commitment': 'الالتزام',
    'performance': 'الأداء',
    'teamwork': 'العمل الجماعي',
    'initiative': 'المبادرة',
  };

  // Genders (NEW)
  static const List<String> genders = ['ذكر', 'أنثى'];
// Educational/Promotion Levels - UPDATED
  static const List<String> educationalLevels = [
    'شبل', // Under 17 years old
    'جدد', // 17 or older
    'داخل متابعة',
    'تدريب',
    'مشروع مسئول',
    'مسئول',
  ];

  // Educational Levels with Order (for sorting) - UPDATED
  static const Map<String, int> educationalLevelsOrder = {
    'مسئول': 6,
    'مشروع مسئول': 5,
    'تدريب': 4,
    'داخل متابعة': 3,
    'جدد': 2,
    'شبل': 2, // SAME LEVEL as جدد
    '': 0,
  };

  // Promotion Requirements for each level - UPDATED
  static const Map<String, List<String>> promotionRequirements = {
    'شبل': [
      'حضر 2 اجتماعات على الأقل',
      'شارك في نشاط تطوعي واحد',
      'أكمل ملف التعريف الشخصي',
      'حضر جلسة تعريفية',
    ],
    'جدد': [
      'حضر 4 اجتماعات على الأقل',
      'شارك في نشاط تطوعي واحد',
      'أكمل ملف التعريف الشخصي',
      'حضر جلسة تعريفية',
    ],
    // Both شبل and جدد promote to داخل متابعة
    'داخل متابعة': [
      'حضر 8 اجتماعات على الأقل',
      'قاد نشاط تطوعي صغير',
      'قدم تقرير عن تجربته',
      'حضر ورشة تدريبية',
    ],
    'تدريب': [
      'أكمل برنامج التدريب الأساسي',
      'شارك في 3 مشاريع كمساعد',
      'قدم عرض تقديمي',
      'حصل على تقييم إيجابي من المدرب',
    ],
    'مشروع مسئول': [
      'قاد مشروع كامل بنجاح',
      'درّب 2 متطوعين جدد',
      'أعد خطة عمل لمشروع جديد',
      'حصل على تقييم ممتاز من المشرف',
    ],
  };

  // Helper method to determine initial educational level based on age
  static String getInitialEducationalLevel(int age) {
    if (age < 17) {
      return 'شبل';
    } else {
      return 'جدد';
    }
  }

  // Helper method to get next level
  static String? getNextLevel(String currentLevel) {
    switch (currentLevel) {
      case 'شبل':
      case 'جدد':
        return 'داخل متابعة';
      case 'داخل متابعة':
        return 'تدريب';
      case 'تدريب':
        return 'مشروع مسئول';
      case 'مشروع مسئول':
        return 'مسئول';
      case 'مسئول':
        return null;
      default:
        return 'داخل متابعة';
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
