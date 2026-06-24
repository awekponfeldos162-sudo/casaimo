import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { guest, host, admin }

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String avatarUrl;
  final UserRole role;
  final bool isVerified;
  final List<String> favoriteIds;
  final DateTime createdAt;
  final String businessName;
  final String businessType;
  final String businessAddress;
  final String businessDescription;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.avatarUrl,
    required this.role,
    required this.isVerified,
    required this.favoriteIds,
    required this.createdAt,
    this.businessName = '',
    this.businessType = '',
    this.businessAddress = '',
    this.businessDescription = '',
  });

  bool get isHost => role == UserRole.host || role == UserRole.admin;
  bool get isAdmin => role == UserRole.admin;
  bool get hasBusiness => businessName.isNotEmpty;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: d['email'] ?? '',
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      avatarUrl: d['avatarUrl'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == d['role'],
        orElse: () => UserRole.guest,
      ),
      isVerified: d['isVerified'] ?? false,
      favoriteIds: List<String>.from(d['favoriteIds'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      businessName: d['businessName'] ?? '',
      businessType: d['businessType'] ?? '',
      businessAddress: d['businessAddress'] ?? '',
      businessDescription: d['businessDescription'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'name': name,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'role': role.name,
    'isVerified': isVerified,
    'favoriteIds': favoriteIds,
    'createdAt': FieldValue.serverTimestamp(),
    if (businessName.isNotEmpty) 'businessName': businessName,
    if (businessType.isNotEmpty) 'businessType': businessType,
    if (businessAddress.isNotEmpty) 'businessAddress': businessAddress,
    if (businessDescription.isNotEmpty) 'businessDescription': businessDescription,
  };

  UserModel copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    UserRole? role,
    bool? isVerified,
    List<String>? favoriteIds,
    String? businessName,
    String? businessType,
    String? businessAddress,
    String? businessDescription,
  }) => UserModel(
    id: id, email: email,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    role: role ?? this.role,
    isVerified: isVerified ?? this.isVerified,
    favoriteIds: favoriteIds ?? this.favoriteIds,
    createdAt: createdAt,
    businessName: businessName ?? this.businessName,
    businessType: businessType ?? this.businessType,
    businessAddress: businessAddress ?? this.businessAddress,
    businessDescription: businessDescription ?? this.businessDescription,
  );
}
