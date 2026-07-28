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
    super.secondaryCommitteeId,
    super.secondaryCommitteeName,
    required super.hasInterview,
    required super.createdAt,
    super.birthDate,
    super.gender,
    super.educationalLevel,
    super.university,
    super.profileImage,
    super.hasTshirt = false,
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
      secondaryCommitteeId: data['secondaryCommitteeId'],
      secondaryCommitteeName: data['secondaryCommitteeName'],
      hasInterview: data['hasInterview'] ?? false,
      hasTshirt: data['hasTshirt'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      birthDate: data['birthDate'],
      gender: data['gender'],
      educationalLevel: data['educationalLevel'],
      university: data['university'],
      profileImage: data['profileImage'],
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
      'secondaryCommitteeId': secondaryCommitteeId,
      'secondaryCommitteeName': secondaryCommitteeName,
      'hasInterview': hasInterview,
      'hasTshirt': hasTshirt ?? false,
      'birthDate': birthDate,
      'gender': gender,
      'educationalLevel': educationalLevel,
      'university': university,
      'profileImage': profileImage,
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
      secondaryCommitteeId: map['secondaryCommitteeId'],
      secondaryCommitteeName: map['secondaryCommitteeName'],
      hasInterview: map['hasInterview'] ?? false,
      hasTshirt: map['hasTshirt'] ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      birthDate: map['birthDate'],
      gender: map['gender'],
      educationalLevel: map['educationalLevel'],
      university: map['university'],
      profileImage: map['profileImage'],
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
      'secondaryCommitteeId': secondaryCommitteeId,
      'secondaryCommitteeName': secondaryCommitteeName,
      'hasInterview': hasInterview,
      'hasTshirt': hasTshirt,
      'birthDate': birthDate,
      'gender': gender,
      'educationalLevel': educationalLevel,
      'university': university,
      'profileImage': profileImage,
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
    String? secondaryCommitteeId,
    String? secondaryCommitteeName,
    bool? hasInterview,
    bool? hasTshirt,
    DateTime? createdAt,
    String? birthDate,
    String? gender,
    String? educationalLevel,
    String? university,
    String? profileImage,
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
      secondaryCommitteeId: secondaryCommitteeId ?? this.secondaryCommitteeId,
      secondaryCommitteeName: secondaryCommitteeName ?? this.secondaryCommitteeName,
      hasInterview: hasInterview ?? this.hasInterview,
      hasTshirt: hasTshirt ?? this.hasTshirt,
      createdAt: createdAt ?? this.createdAt,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      educationalLevel: educationalLevel ?? this.educationalLevel,
      university: university ?? this.university,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
