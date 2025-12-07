// ============================================
// FILE: lib/data/models/volunteer_model.dart
// UPDATED: Added all fields including new ones from redesign
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/volunteer.dart';

class VolunteerModel extends Volunteer {
  VolunteerModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.email,
    required super.address,
    super.nationalId,
    super.age,
    super.committeeId,
    super.committeeName,
    required super.hasInterview,
    required super.createdAt,
    super.birthDate, // ADD THIS
    super.gender, // ADD THIS
    super.educationalLevel, // ADD THIS - from redesign
    super.university, // ADD THIS - from redesign
    super.profileImage, // ADD THIS - from redesign
    super.hasTshirt = false, // Moved to super
  });

  // From Firestore
  factory VolunteerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VolunteerModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      nationalId: data['nationalId'],
      age: data['age'],
      committeeId: data['committeeId'],
      committeeName: data['committeeName'],
      hasInterview: data['hasInterview'] ?? false,
      hasTshirt: data['hasTshirt'] ?? false, // Changed to super
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      birthDate: data['birthDate'], // ADD THIS
      gender: data['gender'], // ADD THIS
      educationalLevel: data['educationalLevel'], // ADD THIS
      university: data['university'], // ADD THIS
      profileImage: data['profileImage'], // ADD THIS
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'nationalId': nationalId,
      'age': age,
      'committeeId': committeeId,
      'committeeName': committeeName,
      'hasInterview': hasInterview,
      'hasTshirt': hasTshirt ?? false, // Updated
      'birthDate': birthDate, // ADD THIS
      'gender': gender, // ADD THIS
      'educationalLevel': educationalLevel, // ADD THIS
      'university': university, // ADD THIS
      'profileImage': profileImage, // ADD THIS
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.now(),
    };
  }

  // From Map
  factory VolunteerModel.fromMap(Map<String, dynamic> map) {
    return VolunteerModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      nationalId: map['nationalId'],
      age: map['age'],
      committeeId: map['committeeId'],
      committeeName: map['committeeName'],
      hasInterview: map['hasInterview'] ?? false,
      hasTshirt: map['hasTshirt'] ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      birthDate: map['birthDate'], // ADD THIS
      gender: map['gender'], // ADD THIS
      educationalLevel: map['educationalLevel'], // ADD THIS
      university: map['university'], // ADD THIS
      profileImage: map['profileImage'], // ADD THIS
    );
  }

  // To Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'nationalId': nationalId,
      'age': age,
      'committeeId': committeeId,
      'committeeName': committeeName,
      'hasInterview': hasInterview,
      'hasTshirt': hasTshirt,
      'birthDate': birthDate, // ADD THIS
      'gender': gender, // ADD THIS
      'educationalLevel': educationalLevel, // ADD THIS
      'university': university, // ADD THIS
      'profileImage': profileImage, // ADD THIS
      'createdAt': createdAt,
    };
  }

  // CopyWith method for updating
  VolunteerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? nationalId,
    int? age,
    String? committeeId,
    String? committeeName,
    bool? hasInterview,
    bool? hasTshirt,
    DateTime? createdAt,
    String? birthDate, // ADD THIS
    String? gender, // ADD THIS
    String? educationalLevel, // ADD THIS
    String? university, // ADD THIS
    String? profileImage, // ADD THIS
  }) {
    return VolunteerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      nationalId: nationalId ?? this.nationalId,
      age: age ?? this.age,
      committeeId: committeeId ?? this.committeeId,
      committeeName: committeeName ?? this.committeeName,
      hasInterview: hasInterview ?? this.hasInterview,
      hasTshirt: hasTshirt ?? this.hasTshirt,
      createdAt: createdAt ?? this.createdAt,
      birthDate: birthDate ?? this.birthDate, // ADD THIS
      gender: gender ?? this.gender, // ADD THIS
      educationalLevel: educationalLevel ?? this.educationalLevel, // ADD THIS
      university: university ?? this.university, // ADD THIS
      profileImage: profileImage ?? this.profileImage, // ADD THIS
    );
  }
}
