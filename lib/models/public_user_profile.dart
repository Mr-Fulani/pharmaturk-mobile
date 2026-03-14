import 'package:json_annotation/json_annotation.dart';

part 'public_user_profile.g.dart';

@JsonSerializable()
class PublicUserProfile {
  final int id;
  @JsonKey(name: 'user_username')
  final String userUsername;
  final String? email;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  @JsonKey(name: 'middle_name')
  final String? middleName;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  final String? bio;
  @JsonKey(name: 'whatsapp_phone')
  final String? whatsappPhone;
  @JsonKey(name: 'telegram_username')
  final String? telegramUsername;
  final String? country;
  final String? city;
  @JsonKey(name: 'testimonial_id')
  final int? testimonialId;
  @JsonKey(name: 'total_orders')
  final int totalOrders;
  @JsonKey(name: 'social_links')
  final Map<String, dynamic>? socialLinks;

  PublicUserProfile({
    required this.id,
    required this.userUsername,
    this.email,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.middleName,
    this.avatarUrl,
    this.bio,
    this.whatsappPhone,
    this.telegramUsername,
    this.country,
    this.city,
    this.testimonialId,
    this.totalOrders = 0,
    this.socialLinks,
  });

  String get fullName {
    final parts = [firstName, lastName].where((p) => p != null && p.toString().isNotEmpty);
    return parts.isNotEmpty ? parts.join(' ') : userUsername;
  }

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) =>
      _$PublicUserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$PublicUserProfileToJson(this);
}
