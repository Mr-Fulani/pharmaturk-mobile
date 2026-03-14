import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../utils/image_url.dart';
import '../models/models.dart';
import '../services/testimonial_service.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import 'public_user_profile_screen.dart';
import 'create_testimonial_screen.dart';
import 'login_screen.dart';

/// Экран со всеми отзывами клиентов.
class TestimonialsScreen extends StatefulWidget {
  const TestimonialsScreen({super.key});

  @override
  State<TestimonialsScreen> createState() => _TestimonialsScreenState();
}

class _TestimonialsScreenState extends State<TestimonialsScreen> {
  late Future<List<Testimonial>> _future;

  @override
  void initState() {
    super.initState();
    _future = TestimonialService().getTestimonials();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = TestimonialService().getTestimonials();
    });
  }

  void _openCreateTestimonial(BuildContext context, AuthProvider auth) {
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('login_to_leave_review'))),
      );
      return;
    }
    if (!auth.isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('verify_to_leave_review')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateTestimonialScreen(),
      ),
    ).then((created) {
      if (created == true && mounted) _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final canLeaveReview = auth.isAuthenticated && auth.isEmailVerified;
        return Scaffold(
          appBar: AppBar(
            title: Text(context.tr('reviews')),
            actions: [
              if (auth.isAuthenticated)
                IconButton(
                  icon: const Icon(Icons.add_comment),
                  tooltip: context.tr('leave_review'),
                  onPressed: () => _openCreateTestimonial(context, auth),
                ),
            ],
          ),
          floatingActionButton: auth.isAuthenticated
              ? FloatingActionButton.extended(
                  onPressed: () => _openCreateTestimonial(context, auth),
                  icon: const Icon(Icons.rate_review),
                  label: Text(context.tr('leave_review')),
                  backgroundColor: canLeaveReview ? Colors.teal : Colors.grey,
                )
              : null,
          body: FutureBuilder<List<Testimonial>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.tr('retry'),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _refresh,
                    child: Text(context.tr('retry')),
                  ),
                ],
              ),
            );
          }
          final list = snapshot.hasData ? snapshot.data! : <Testimonial>[];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.tr('no_reviews'),
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                if (!auth.isAuthenticated)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.teal[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.tr('login_to_leave_review'),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            child: Text(context.tr('login')),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _TestimonialCard(testimonial: list[i]),
                      ),
                      childCount: list.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
          ),
        );
      },
    );
  }
}

class _TestimonialCard extends StatefulWidget {
  final Testimonial testimonial;

  const _TestimonialCard({required this.testimonial});

  @override
  State<_TestimonialCard> createState() => _TestimonialCardState();
}

class _TestimonialCardState extends State<_TestimonialCard> {
  VideoPlayerController? _videoController;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    _initFirstVideoIfAny();
  }

  void _initFirstVideoIfAny() {
    final media = widget.testimonial.media;
    if (media == null || media.isEmpty) return;
    for (final m in media) {
      final url = resolveImageUrlOrNull(m.file);
      if (url != null && isVideoUrl(url)) {
        _initVideo(url);
        return;
      }
    }
  }

  Future<void> _initVideo(String url) async {
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await ctrl.initialize();
      if (mounted) {
        setState(() {
          _videoController = ctrl;
          ctrl.setVolume(0);
          ctrl.setLooping(true);
        });
      } else {
        ctrl.dispose();
      }
    } on PlatformException catch (_) {
      if (mounted) setState(() => _videoError = true);
    } catch (_) {
      if (mounted) setState(() => _videoError = true);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.testimonial;
    final media = t.media ?? [];
    final hasMedia = media.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasMedia) _buildMediaSection(media),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAvatar(context, t),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (t.authorName.isNotEmpty)
                            _buildAuthorName(context, t),
                          if (t.rating > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < t.rating ? Icons.star : Icons.star_border,
                                  size: 18,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  t.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, Testimonial t) {
    final avatar = ClipOval(
      child: t.authorAvatar != null
          ? CachedNetworkImage(
              imageUrl: resolveImageUrl(t.authorAvatar),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _avatarPlaceholder(t.authorName),
            )
          : _avatarPlaceholder(t.authorName),
    );
    if (t.userId != null && t.userUsername != null && t.userUsername!.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PublicUserProfileScreen(
                username: t.userUsername,
                testimonialId: t.id,
              ),
            ),
          );
        },
        child: avatar,
      );
    }
    return avatar;
  }

  Widget _buildAuthorName(BuildContext context, Testimonial t) {
    final nameWidget = Text(
      t.authorName,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
    if (t.userId != null && t.userUsername != null && t.userUsername!.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PublicUserProfileScreen(
                username: t.userUsername,
                testimonialId: t.id,
              ),
            ),
          );
        },
        child: nameWidget,
      );
    }
    return nameWidget;
  }

  Widget _avatarPlaceholder(String name) {
    return Container(
      width: 48,
      height: 48,
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMediaSection(List<TestimonialMedia> media) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: SizedBox(
        height: 200,
        child: _buildSingleMedia(media.first),
      ),
    );
  }

  Widget _buildSingleMedia(TestimonialMedia m) {
    final url = resolveImageUrlOrNull(m.file);
    if (url == null || url.isEmpty) {
      return _buildPlaceholder();
    }
    if (isVideoUrl(url)) {
      if (_videoError) return _buildVideoPlaceholder();
      if (_videoController != null && _videoController!.value.isInitialized) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        );
      }
      return _buildVideoPlaceholder();
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.image, size: 48, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.play_circle_fill, size: 56, color: Colors.teal[300]),
      ),
    );
  }
}
