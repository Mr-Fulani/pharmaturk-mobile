import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/public_user_profile.dart';
import '../services/user_service.dart';
import '../utils/image_url.dart';
import '../l10n/app_localizations.dart';

/// Экран публичного профиля пользователя (по username или testimonial_id).
class PublicUserProfileScreen extends StatefulWidget {
  final String? username;
  final int? testimonialId;

  const PublicUserProfileScreen({
    super.key,
    this.username,
    this.testimonialId,
  });

  @override
  State<PublicUserProfileScreen> createState() => _PublicUserProfileScreenState();
}

class _PublicUserProfileScreenState extends State<PublicUserProfileScreen> {
  final UserService _userService = UserService();
  PublicUserProfile? _profile;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
      _profile = null;
    });
    try {
      final profile = await _userService.getPublicProfile(
        username: widget.username,
        testimonialId: widget.testimonialId,
      );
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      final msg = e.toString();
      if (mounted) {
        setState(() {
          _error = msg;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('profile'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      final isProfileNotPublic = UserService.isProfileNotPublicError(_error!);
      final isUserNotFound = UserService.isUserNotFoundError(_error!);
      final message = isProfileNotPublic
          ? context.tr('profile_not_public')
          : isUserNotFound
              ? context.tr('user_not_found')
              : _error;

      return Scaffold(
        appBar: AppBar(title: Text(context.tr('profile'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isProfileNotPublic ? Icons.lock_outline : Icons.person_off_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr('back_to_home')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('profile'))),
        body: const Center(child: Text('Нет данных')),
      );
    }

    return _buildProfileContent(_profile!);
  }

  Widget _buildProfileContent(PublicUserProfile profile) {
    return Scaffold(
      appBar: AppBar(title: Text(profile.fullName)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(profile),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    Text(
                      profile.bio!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (profile.email != null || profile.phoneNumber != null) ...[
                    _buildSectionTitle(context.tr('contact_info')),
                    if (profile.email != null)
                      _buildContactRow(
                        Icons.email_outlined,
                        profile.email!,
                        'mailto:${profile.email}',
                      ),
                    if (profile.phoneNumber != null)
                      _buildContactRow(
                        Icons.phone_outlined,
                        profile.phoneNumber!,
                        'tel:${profile.phoneNumber}',
                      ),
                    const SizedBox(height: 24),
                  ],
                  _buildStatsRow(profile),
                  if (_hasSocialLinks(profile.socialLinks)) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle(context.tr('social_networks')),
                    const SizedBox(height: 8),
                    _buildSocialLinks(profile.socialLinks!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PublicUserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade50,
            Colors.teal.shade100.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white,
            child: profile.avatarUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: resolveImageUrl(profile.avatarUrl),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _avatarPlaceholder(profile.fullName),
                    ),
                  )
                : _avatarPlaceholder(profile.fullName),
          ),
          const SizedBox(height: 16),
          Text(
            profile.fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.teal[700]),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _launchUrl(url),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.teal,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildStatsRow(PublicUserProfile profile) {
    return Row(
      children: [
        Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '${profile.totalOrders} ${context.tr('orders_count')}',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }

  bool _hasSocialLinks(Map<String, dynamic>? links) {
    if (links == null) return false;
    for (final v in links.values) {
      if (v != null && v.toString().isNotEmpty) return true;
    }
    return false;
  }

  Widget _buildSocialLinks(Map<String, dynamic> links) {
    final widgets = <Widget>[];
    if (links['telegram'] != null && links['telegram'].toString().isNotEmpty) {
      widgets.add(_socialButton('Telegram', links['telegram'].toString(), Icons.send));
    }
    if (links['whatsapp'] != null && links['whatsapp'].toString().isNotEmpty) {
      widgets.add(_socialButton('WhatsApp', links['whatsapp'].toString(), Icons.chat));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widgets,
    );
  }

  Widget _socialButton(String label, String url, IconData icon) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.teal),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
