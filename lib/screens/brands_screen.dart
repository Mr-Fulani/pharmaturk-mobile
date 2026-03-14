import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';
import '../models/models.dart' as app_models;
import '../providers/providers.dart';
import '../utils/image_url.dart';
import '../l10n/app_localizations.dart';
import '../widgets/brand_card.dart';

/// Экран «Все бренды»: баннеры сверху и снизу, сетка всех брендов.
class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().getBanners();
      context.read<CatalogProvider>().getBrands();
    });
  }

  List<app_models.Banner> _bannersAtPosition(CatalogProvider provider, String position) {
    return provider.banners
        .where((b) =>
            b.position == position &&
            b.mediaFiles != null &&
            b.mediaFiles!.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('all_brands')),
      ),
      body: Consumer<CatalogProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingBrands && provider.brands.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final topBanners = _bannersAtPosition(provider, 'main');
          final bottomBanners = _bannersAtPosition(provider, 'after_brands');

          return CustomScrollView(
            slivers: [
              if (topBanners.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: SizedBox(
                      height: 220,
                      child: CarouselSlider.builder(
                        itemCount: topBanners.length,
                        itemBuilder: (context, index, _) =>
                            _BannerSlide(banner: topBanners[index]),
                        options: CarouselOptions(
                          height: 220,
                          viewportFraction: 0.92,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: false,
                          autoPlay: topBanners.length > 1,
                          autoPlayInterval: const Duration(seconds: 5),
                        ),
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => BrandCard(brand: provider.brands[index]),
                    childCount: provider.brands.length,
                  ),
                ),
              ),
              if (bottomBanners.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: SizedBox(
                      height: 220,
                      child: CarouselSlider.builder(
                        itemCount: bottomBanners.length,
                        itemBuilder: (context, index, _) =>
                            _BannerSlide(banner: bottomBanners[index]),
                        options: CarouselOptions(
                          height: 220,
                          viewportFraction: 0.92,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: false,
                          autoPlay: bottomBanners.length > 1,
                          autoPlayInterval: const Duration(seconds: 5),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BannerSlide extends StatefulWidget {
  final app_models.Banner banner;

  const _BannerSlide({required this.banner});

  @override
  State<_BannerSlide> createState() => _BannerSlideState();
}

class _BannerSlideState extends State<_BannerSlide> {
  VideoPlayerController? _controller;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    final media = widget.banner.mediaFiles ?? [];
    if (media.isNotEmpty) {
      final url = resolveImageUrlOrNull(media.first.file);
      if (url != null && _isVideoUrl(url)) _initVideo(url);
    }
  }

  bool _isVideoUrl(String url) {
    final path = url.split('?').first.toLowerCase();
    return path.endsWith('.mp4') || path.endsWith('.webm') ||
        path.endsWith('.mov') || path.endsWith('.m4v');
  }

  Future<void> _initVideo(String url) async {
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await ctrl.initialize();
      if (mounted) {
        setState(() {
          _controller = ctrl;
          ctrl.setVolume(0);
          ctrl.setLooping(true);
          ctrl.play();
        });
      } else {
        ctrl.dispose();
      }
    } catch (_) {
      if (mounted) setState(() => _videoError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.banner.mediaFiles ?? [];
    if (media.isEmpty) {
      return _placeholder();
    }
    final url = resolveImageUrlOrNull(media.first.file);
    if (url == null) return _placeholder();
    if (_isVideoUrl(url)) {
      if (_videoError) return _videoPlaceholder();
      if (_controller != null && _controller!.value.isInitialized) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
        );
      }
      return _videoPlaceholder();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorWidget: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[300],
        ),
        child: Center(
          child: Text(
            widget.banner.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );

  Widget _videoPlaceholder() => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[300],
        ),
        child: Center(
          child: Icon(Icons.play_circle_fill, size: 48, color: Colors.teal[300]),
        ),
      );
}
