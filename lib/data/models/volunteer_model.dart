// ============================================
// FILE: lib/data/models/volunteer_model.dart
// UPDATED: Added hasTshirt field
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/volunteer.dart';

class VolunteerModel extends Volunteer {
  final bool hasTshirt;

  VolunteerModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.email,
    required super.address,
    super.nationalId,
    required super.hasInterview,
    required super.createdAt,
    this.hasTshirt = false,
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
      hasInterview: data['hasInterview'] ?? false,
      hasTshirt: data['hasTshirt'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
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
      'hasInterview': hasInterview,
      'hasTshirt': hasTshirt,
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
      hasInterview: map['hasInterview'] ?? false,
      hasTshirt: map['hasTshirt'] ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
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
      'hasInterview': hasInterview,
      'hasTshirt': hasTshirt,
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
    bool? hasInterview,
    bool? hasTshirt,
    DateTime? createdAt,
  }) {
    return VolunteerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      nationalId: nationalId ?? this.nationalId,
      hasInterview: hasInterview ?? this.hasInterview,
      hasTshirt: hasTshirt ?? this.hasTshirt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
