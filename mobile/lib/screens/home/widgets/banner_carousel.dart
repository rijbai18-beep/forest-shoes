import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../config/theme.dart';
import '../../../models/banner_model.dart';

class BannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;
  const BannerCarousel({super.key, required this.banners});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 200,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            enlargeCenterPage: false,
            viewportFraction: 1.0,
            onPageChanged: (index, _) =>
                setState(() => _current = index),
          ),
          items: widget.banners.map((banner) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.divider,
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: banner.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Container(
                  color: AppColors.divider,
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: AppColors.textHint),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        AnimatedSmoothIndicator(
          activeIndex: _current,
          count: widget.banners.length,
          effect: const ExpandingDotsEffect(
            dotWidth: 8,
            dotHeight: 8,
            activeDotColor: AppColors.primary,
            dotColor: AppColors.divider,
          ),
        ),
      ],
    );
  }
}
