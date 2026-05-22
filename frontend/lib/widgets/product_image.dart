import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _buildPlaceholderImage();
    }

    try {
      final cleanUrl = imageUrl!.trim();

      if (cleanUrl.startsWith('data:image')) {
        // Base64 Data URI (e.g. data:image/png;base64,iVBORw0KGgo...)
        final commaIndex = cleanUrl.indexOf(',');
        if (commaIndex != -1) {
          final base64Str = cleanUrl.substring(commaIndex + 1);
          final bytes = base64.decode(base64Str);
          return _buildRoundedImage(Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
          ));
        }
      } else if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
        // Network image
        return _buildRoundedImage(Image.network(
          cleanUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
        ));
      } else if (cleanUrl.startsWith('/')) {
        // Relative path
        final fullUrl = '${Constants.baseUrl}$cleanUrl';
        return _buildRoundedImage(Image.network(
          fullUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
        ));
      } else {
        // Attempt decoding raw base64 string
        final bytes = base64.decode(cleanUrl);
        return _buildRoundedImage(Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
        ));
      }
    } catch (_) {
      // Fallback on error
    }

    return _buildPlaceholderImage();
  }

  Widget _buildRoundedImage(Widget image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: image,
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Icon(
        Icons.restaurant_rounded,
        color: Colors.amber,
        size: size * 0.375, // Scaled size
      ),
    );
  }
}
