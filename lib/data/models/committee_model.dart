// ============================================
// FILE: lib/data/models/committee_model.dart
// UPDATED: Added copyWith method
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/committee.dart';

class CommitteeModel extends Committee {
  static const Object _unset = Object();
  CommitteeModel({

    required super.id,
    required super.name,
    required super.isActive,
    required super.createdAt,
    super.leaderId,
    super.leaderName,
    super.coLeaderId,
    super.coLeaderName,
  });

  factory CommitteeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommitteeModel(
      id: doc.id,
      name: data['name'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      leaderId: data['leaderId'],
      leaderName: data['leaderName'],
      coLeaderId: data['coLeaderId'],
      coLeaderName: data['coLeaderName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'isActive': isActive,
      'leaderId': leaderId,
      'leaderName': leaderName,
      'coLeaderId': coLeaderId,
      'coLeaderName': coLeaderName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.now(),
    };
  }

  CommitteeModel copyWith({
    String? id,
    String? name,
    bool? isActive,
    DateTime? createdAt,

    Object? leaderId = _unset,
    Object? leaderName = _unset,
    Object? coLeaderId = _unset,
    Object? coLeaderName = _unset,
  }) {
    return CommitteeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,

      leaderId: leaderId == _unset ? this.leaderId : leaderId as String?,

      leaderName: leaderName == _unset
          ? this.leaderName
          : leaderName as String?,

      coLeaderId: coLeaderId == _unset
          ? this.coLeaderId
          : coLeaderId as String?,

      coLeaderName: coLeaderName == _unset
          ? this.coLeaderName
          : coLeaderName as String?,
    );
  }

}
