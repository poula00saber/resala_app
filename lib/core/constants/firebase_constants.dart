// ============================================
// FILE: lib/core/constants/firebase_constants.dart
// MERGED - All constants in one place
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

  // Field names for Volunteers (NEW)
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
