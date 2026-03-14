import 'package:json_annotation/json_annotation.dart';

part 'testimonial.g.dart';

@JsonSerializable()
class Testimonial {
  final int id;
  @JsonKey(name: 'author_name')
  final String authorName;
  final String? authorEmail;
  @JsonKey(name: 'author_avatar_url')
  final String? authorAvatar;
  @JsonKey(name: 'text')
  final String content;
  @JsonKey(fromJson: _ratingFromJson)
  final int rating;
  @JsonKey(name: 'is_active', defaultValue: true)
  final bool isActive;
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  final DateTime createdAt;
  final List<TestimonialMedia>? media;
  @JsonKey(name: 'user_id')
  final int? userId;
  @JsonKey(name: 'user_username')
  final String? userUsername;

  Testimonial({
    required this.id,
    required this.authorName,
    this.authorEmail,
    this.authorAvatar,
    required this.content,
    required this.rating,
    this.isActive = true,
    required this.createdAt,
    this.media,
    this.userId,
    this.userUsername,
  });

  factory Testimonial.fromJson(Map<String, dynamic> json) => _$TestimonialFromJson(json);
  Map<String, dynamic> toJson() => _$TestimonialToJson(this);
}

int _ratingFromJson(dynamic v) => (v is num) ? v.toInt() : 0;

DateTime _dateTimeFromJson(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is String) return DateTime.parse(v);
  return DateTime.now();
}

DateTime _mediaCreatedAtFromJson(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is String) return DateTime.parse(v);
  return DateTime.now();
}

@JsonSerializable()
class TestimonialMedia {
  final int id;
  final String file;
  final String? caption;
  @JsonKey(name: 'created_at', fromJson: _mediaCreatedAtFromJson)
  final DateTime createdAt;

  TestimonialMedia({
    required this.id,
    required this.file,
    this.caption,
    required this.createdAt,
  });

  factory TestimonialMedia.fromJson(Map<String, dynamic> json) => _$TestimonialMediaFromJson(json);
  Map<String, dynamic> toJson() => _$TestimonialMediaToJson(this);
}

@JsonSerializable()
class TestimonialCreate {
  final String content;
  final int rating;
  final List<String>? mediaFiles;

  TestimonialCreate({
    required this.content,
    required this.rating,
    this.mediaFiles,
  });

  factory TestimonialCreate.fromJson(Map<String, dynamic> json) => _$TestimonialCreateFromJson(json);
  Map<String, dynamic> toJson() => _$TestimonialCreateToJson(this);
}
