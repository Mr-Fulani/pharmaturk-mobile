import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../utils/image_url.dart';
import '../screens/catalog_screen.dart';

/// Карточка бренда с медиа, оверлеем, логотипом и названием.
class BrandCard extends StatelessWidget {
  final Brand brand;
  final bool compact;

  const BrandCard({required this.brand, this.compact = false});

  static bool _isVideoUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final path = url.split('?').first.toLowerCase();
    return path.endsWith('.mp4') || path.endsWith('.webm') ||
        path.endsWith('.mov') || path.endsWith('.m4v');
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrl = brand.cardMediaUrl ?? brand.logo;
    final url = resolveImageUrlOrNull(mediaUrl);
    final isVideo = _isVideoUrl(mediaUrl);
    final logoUrl = resolveImageUrlOrNull(brand.logo);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CatalogScreen(
            brandId: brand.id,
            brandName: brand.name,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url != null && !isVideo)
                CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: _buildContent(context, showLogo: false),
                  ),
                )
              else
                Container(
                  color: Colors.grey[300],
                  child: _buildContent(context, showLogo: false),
                ),
              Container(
                color: Colors.black.withOpacity(0.35),
              ),
              Center(
                child: _buildContent(
                  context,
                  showLogo: logoUrl != null && !_isVideoUrl(brand.logo),
                  logoUrl: logoUrl,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, {bool showLogo = false, String? logoUrl}) {
    final fontSize = compact ? 14.0 : 16.0;
    final logoHeight = compact ? 28.0 : 36.0;
    return Padding(
      padding: EdgeInsets.all(compact ? 8 : 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showLogo && logoUrl != null) ...[
            CachedNetworkImage(
              imageUrl: logoUrl,
              height: logoHeight,
              fit: BoxFit.contain,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
            SizedBox(height: compact ? 4 : 8),
          ],
          Text(
            brand.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (!compact && brand.description != null && brand.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              brand.description!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
