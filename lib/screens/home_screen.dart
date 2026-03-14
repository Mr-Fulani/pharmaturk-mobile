import 'package:flutter/material.dart' hide Banner;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../utils/image_url.dart';
import '../utils/price_format.dart';
import '../providers/providers.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/testimonial_service.dart';
import 'product_detail_screen.dart';
import 'catalog_screen.dart';
import 'search_screen.dart';
import 'visual_search_screen.dart';
import 'testimonials_screen.dart';
import 'public_user_profile_screen.dart';
import 'brands_screen.dart';
import '../widgets/brand_card.dart';
import '../utils/app_spacing.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _lastLocale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.read<LocaleProvider>().locale.languageCode;
    if (_lastLocale != null && _lastLocale != locale) {
      _lastLocale = locale;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    } else if (_lastLocale == null) {
      _lastLocale = locale;
    }
  }

  Future<void> _loadData() async {
    final catalogProvider = context.read<CatalogProvider>();
    await Future.wait([
      catalogProvider.getBanners(),
      catalogProvider.getFeaturedProducts(),
      catalogProvider.getCategories(topLevel: true),
      catalogProvider.getBrands(),
    ]);
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildBannersAtPosition('main'),
            _sliverGap(AppSpacing.sectionGap),
            _buildBrands(),
            _buildBannersAtPosition('after_brands'),
            _sliverGap(AppSpacing.sectionGap),
            _buildCategoriesWithCatalog(),
            _sliverGap(AppSpacing.sectionGap),
            _buildTestimonials(),
            _buildBannersAtPosition('before_footer'),
            _sliverGap(AppSpacing.sectionGap),
            _buildFeaturedProducts(),
            _buildBannersAtPosition('after_popular_products'),
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      title: const Text(
        'Turk Export',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // TODO: Navigate to notifications
          },
        ),
        IconButton(
          icon: const Icon(Icons.favorite_outline),
          onPressed: () {
            // TODO: Navigate to favorites
          },
        ),
      ],
    );
  }

  SliverToBoxAdapter _sliverGap(double height) {
    return SliverToBoxAdapter(child: SizedBox(height: height));
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  showSearch(
                    context: context,
                    delegate: ProductSearchScreen(
                      searchHint: context.tr('search_placeholder'),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(
                        context.tr('search_placeholder'),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VisualSearchScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannersAtPosition(String position) {
    return Consumer<CatalogProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingBanners) {
          return const SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final bannersWithMedia = provider.banners
            .where((b) =>
                b.position == position &&
                b.mediaFiles != null &&
                b.mediaFiles!.isNotEmpty)
            .toList();
        if (bannersWithMedia.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 240,
              child: CarouselSlider.builder(
                itemCount: bannersWithMedia.length,
                itemBuilder: (context, index, _) {
                  return _BannerCard(banner: bannersWithMedia[index]);
                },
                options: CarouselOptions(
                height: 240,
                viewportFraction: 0.92,
                enlargeCenterPage: true,
                enableInfiniteScroll: false,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
              ),
            ),
          ),
        ),
        );
      },
    );
  }

  Widget _buildTestimonials() {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<Testimonial>>(
        future: TestimonialService().getTestimonials(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('reviews'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: 14, color: Colors.red[700]),
                  ),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('reviews'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              ),
            );
          }
          final list = snapshot.hasData ? snapshot.data! : <Testimonial>[];
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('reviews'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('no_reviews'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('reviews'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TestimonialsScreen(),
                          ),
                        );
                      },
                      child: Text(context.tr('show_all_reviews')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 440,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final t = list[i];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TestimonialsScreen(),
                          ),
                        );
                      },
                      child: _TestimonialCard(testimonial: t),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoriesWithCatalog() {
    return Consumer<CatalogProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingCategories) {
          return const SliverToBoxAdapter(
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (provider.categories.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('categories'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CatalogScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.category, size: 20),
                        label: Text(context.tr('catalog')),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.categories.length,
                    itemBuilder: (context, index) {
                      final category = provider.categories[index];
                      return _CategoryCard(category: category);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedProducts() {
    return Consumer<CatalogProvider>(
      builder: (context, provider, child) {
        if (provider.featuredProducts.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('recommended'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CatalogScreen(),
                          ),
                        );
                      },
                      child: Text(context.tr('all')),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.featuredProducts.length,
                  itemBuilder: (context, index) {
                    final product = provider.featuredProducts[index];
                    return _ProductCard(product: product);
                  },
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildBrands() {
    return Consumer<CatalogProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingBrands) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        if (provider.brands.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final sorted = List<Brand>.from(provider.brands)
          ..sort((a, b) {
            final ac = int.tryParse(a.productsCount) ?? 0;
            final bc = int.tryParse(b.productsCount) ?? 0;
            return bc.compareTo(ac);
          });
        final topBrands = sorted.take(6).toList();

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('popular_brands'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: topBrands.length,
                    itemBuilder: (context, index) {
                      return BrandCard(brand: topBrands[index], compact: true);
                    },
                  ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BrandsScreen(),
                      ),
                    ),
                    child: Text(context.tr('all_brands')),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Banner banner;

  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    final media = banner.mediaFiles ?? [];
    if (media.isEmpty) {
      return _buildFallback(context);
    }

    return GestureDetector(
      onTap: () {
        if (banner.linkUrl != null) {
          // TODO: Handle banner click
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[300],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: media.length == 1
              ? _BannerMediaSlide(
                  url: media.first.file,
                  title: media.first.title ?? banner.title,
                )
              : CarouselSlider.builder(
                  itemCount: media.length,
                  itemBuilder: (context, index, _) {
                    final m = media[index];
                    return _BannerMediaSlide(
                      url: m.file,
                      title: m.title ?? banner.title,
                    );
                  },
                  options: CarouselOptions(
                    height: 240,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: false,
                    autoPlay: media.length > 1,
                    autoPlayInterval: const Duration(seconds: 4),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[300],
      ),
      child: Center(
        child: Text(
          banner.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Один слайд медиа баннера (изображение или видео).
class _BannerMediaSlide extends StatefulWidget {
  final String url;
  final String title;

  const _BannerMediaSlide({required this.url, required this.title});

  @override
  State<_BannerMediaSlide> createState() => _BannerMediaSlideState();
}

class _BannerMediaSlideState extends State<_BannerMediaSlide> {
  VideoPlayerController? _controller;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    final resolved = resolveImageUrlOrNull(widget.url);
    if (resolved != null && isVideoUrl(resolved)) {
      _initVideo(resolved);
    }
  }

  Future<void> _initVideo(String url) async {
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await ctrl.initialize();
      if (mounted) {
        setState(() {
          _controller = ctrl;
          ctrl.setVolume(0); // Без звука по умолчанию
          ctrl.setLooping(true);
          ctrl.play();
        });
      } else {
        ctrl.dispose();
      }
    } on PlatformException catch (_) {
      // iOS симулятор / канал не инициализирован — показываем placeholder
      if (mounted) setState(() => _videoError = true);
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
    final resolved = resolveImageUrlOrNull(widget.url);
    if (resolved == null) {
      return _buildPlaceholder();
    }
    if (isVideoUrl(resolved)) {
      if (_videoError) return _buildVideoPlaceholder();
      if (_controller != null && _controller!.value.isInitialized) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        );
      }
      return _buildVideoPlaceholder();
    }
    return CachedNetworkImage(
      imageUrl: resolved,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorWidget: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        widget.title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_fill, size: 48, color: Colors.teal[300]),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CatalogScreen(
              categorySlug: category.slug,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: () {
                    final url = resolveImageUrlOrNull(category.cardMediaUrl);
                    return url != null
                        ? CachedNetworkImage(
                            imageUrl: url,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey[200],
                              child: const Icon(Icons.category, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 56,
                            height: 56,
                            color: Colors.grey[200],
                            child: const Icon(Icons.category, color: Colors.grey),
                          );
                  }(),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(slug: product.slug),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1,
                child: (product.mainImageUrl != null || product.videoUrl != null)
                    ? (() {
                        final url = resolveImageUrlOrNull(product.mainImageUrl);
                        return url != null
                            ? CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: Icon(Icons.play_circle_fill, size: 48, color: Colors.teal[300]),
                                ),
                              );
                      }())
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatPriceWithCurrency(product.price, product.currency),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  if (hasValidOldPrice(product.oldPrice))
                    Text(
                      formatPriceWithCurrency(product.oldPrice, product.currency),
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка отзыва на главной: вертикальная (aspect 9:16), медиа, текст, футер с аватаркой.
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
          ctrl.play();
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
      width: 168,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: hasMedia
                  ? _buildMedia(media.first)
                  : Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey[400]),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildAvatarSection(context, t),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildAuthorNameSection(context, t),
                    ),
                    if (t.rating > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < t.rating ? Icons.star : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, Testimonial t) {
    final avatar = ClipOval(
      child: t.authorAvatar != null
          ? CachedNetworkImage(
              imageUrl: resolveImageUrl(t.authorAvatar),
              width: 32,
              height: 32,
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

  Widget _buildAuthorNameSection(BuildContext context, Testimonial t) {
    final nameWidget = Text(
      t.authorName,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
      width: 32,
      height: 32,
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMedia(TestimonialMedia m) {
    final url = resolveImageUrlOrNull(m.file);
    if (url == null || url.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.image, size: 32, color: Colors.grey[400]),
        ),
      );
    }
    if (isVideoUrl(url)) {
      if (_videoError) {
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: Icon(Icons.play_circle_fill, size: 40, color: Colors.teal[300]),
          ),
        );
      }
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
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.play_circle_fill, size: 40, color: Colors.teal[300]),
        ),
      );
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
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
        ),
      ),
    );
  }
}

