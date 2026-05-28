import 'package:cloud_firestore/cloud_firestore.dart';

class ScWithdrawModel {
  final String userId;
  final String? email;
  final String withdrawType;
  final String withdrawSubType;
  final double amount;
  final String? note;
  final String status;
  final DateTime? createdAt;

  ScWithdrawModel({
    required this.userId,
    required this.withdrawType,
    required this.withdrawSubType,
    required this.amount,
    this.email,
    this.note,
    this.status = 'pending',
    this.createdAt,
  });

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'email': email,
      'withdraw_type': withdrawType,
      'withdraw_sub_type': withdrawSubType,
      'amount': amount,
      'note': note,
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  /// Convert from Firestore
  factory ScWithdrawModel.fromMap(Map<String, dynamic> map) {
    return ScWithdrawModel(
      userId: map['user_id'],
      email: map['email'],
      withdrawType: map['withdraw_type'],
      withdrawSubType: map['withdraw_sub_type'],
      amount: (map['amount'] as num).toDouble(),
      note: map['note'],
      status: map['status'] ?? 'pending',
      createdAt: map['created_at'] != null
          ? (map['created_at'] as Timestamp).toDate()
          : null,
    );
  }

  factory ScWithdrawModel.fromLocalMap(Map<String, dynamic> map) {
    return ScWithdrawModel(
      userId: map['user_id'],
      email: map['email'],
      withdrawType: map['withdraw_type'],
      withdrawSubType: map['withdraw_sub_type'],
      amount: (map['amount'] as num).toDouble(),
      note: map['note'],
      status: map['status'] ?? 'pending',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  ScWithdrawModel copyWith({
    String? userId,
    String? email,
    String? withdrawType,
    String? withdrawSubType,
    double? amount,
    String? note,
    String? status,
    DateTime? createdAt,
  }) {
    return ScWithdrawModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      withdrawType: withdrawType ?? this.withdrawType,
      withdrawSubType: withdrawSubType ?? this.withdrawSubType,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
