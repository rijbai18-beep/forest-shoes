import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/cache_config.dart';
import '../../../config/constants.dart';
import '../../../config/theme.dart';

class EngravingWidget extends StatefulWidget {
  final bool enabled;
  final String? initialText;
  final String? imageUrl;
  final void Function(String? text) onChanged;

  const EngravingWidget({
    super.key,
    required this.enabled,
    this.initialText,
    this.imageUrl,
    required this.onChanged,
  });

  @override
  State<EngravingWidget> createState() => _EngravingWidgetState();
}

class _EngravingWidgetState extends State<EngravingWidget> {
  late TextEditingController _ctrl;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
    _isEnabled = widget.enabled && widget.initialText != null;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personalization / Engraving',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      'Add up to ${AppConstants.engravingMaxChars} characters',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (v) {
                  setState(() {
                    _isEnabled = v;
                    if (!v) {
                      _ctrl.clear();
                      widget.onChanged(null);
                    }
                  });
                },
              ),
            ],
          ),
          if (_isEnabled) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              maxLength: AppConstants.engravingMaxChars,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 &]')),
                LengthLimitingTextInputFormatter(AppConstants.engravingMaxChars),
              ],
              decoration: const InputDecoration(
                hintText: 'e.g. ALEX 2024',
                counterText: '',
              ),
              onChanged: (v) => widget.onChanged(v.isEmpty ? null : v),
            ),
            const SizedBox(height: 12),
            // Text preview on shoe
            _EngravingPreview(text: _ctrl.text, imageUrl: widget.imageUrl),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Engraving fee: Rs ${AppConstants.engravingFee.toInt()} per item',
                      style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EngravingPreview extends StatelessWidget {
  final String text;
  final String? imageUrl;
  const _EngravingPreview({required this.text, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Product image (or placeholder background)
          if (imageUrl != null && imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              cacheManager: AppCacheManager(),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder,
              errorWidget: (_, __, ___) => _placeholder,
            )
          else
            _placeholder,

          // Dark gradient at bottom so text is always readable
          Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
                stops: [0.45, 1.0],
              ),
            ),
          ),

          // Engraving text overlay
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: text.isEmpty
                  ? const Text(
                      'Your text here',
                      key: ValueKey('placeholder'),
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 2,
                      ),
                    )
                  : Text(
                      text.toUpperCase(),
                      key: ValueKey(text),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black54),
                        ],
                      ),
                    ),
            ),
          ),

          // "Preview" label top-left
          const Positioned(
            top: 8,
            left: 10,
            child: Text(
              'PREVIEW',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _placeholder => Container(
        height: 180,
        color: AppColors.primaryDark.withValues(alpha: 0.08),
        child: const Center(
          child: Icon(Icons.photo_outlined, size: 60, color: Color(0x1A2E7D32)),
        ),
      );
}
