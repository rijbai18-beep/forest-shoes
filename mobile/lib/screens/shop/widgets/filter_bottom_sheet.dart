import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/product_model.dart';
import '../../../services/product_service.dart';
import '../../../widgets/common/custom_button.dart';

class FilterBottomSheet extends StatefulWidget {
  final ProductFilter currentFilter;
  final List<CategoryModel> categories;
  final void Function(ProductFilter) onApply;

  const FilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.categories,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _category;
  late String? _gender;
  late String? _color;
  late String? _size;
  late bool? _onSaleOnly;
  late bool? _inStockOnly;
  late SortOption _sort;

  final _rangeValues = const RangeValues(0, 5000);
  RangeValues _currentRange = const RangeValues(0, 5000);

  static const _genders = ['men', 'women', 'kids', 'unisex'];
  static const _sizes = [
    '36', '37', '38', '39', '40', '41', '42', '43', '44', '45', '46'
  ];
  static const _colors = [
    'Black', 'White', 'Brown', 'Grey', 'Navy', 'Green', 'Red', 'Blue'
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.currentFilter;
    _category = f.category;
    _gender = f.gender;
    _color = f.color;
    _size = f.size;
    _onSaleOnly = f.onSaleOnly;
    _inStockOnly = f.inStockOnly;
    _sort = f.sort;
    _currentRange = RangeValues(f.minPrice ?? 0, f.maxPrice ?? 5000);
  }

  void _reset() {
    setState(() {
      _category = null;
      _gender = null;
      _color = null;
      _size = null;
      _onSaleOnly = null;
      _inStockOnly = null;
      _sort = SortOption.newest;
      _currentRange = const RangeValues(0, 5000);
    });
  }

  void _apply() {
    widget.onApply(ProductFilter(
      category: _category,
      gender: _gender,
      color: _color,
      size: _size,
      minPrice: _currentRange.start > 0 ? _currentRange.start : null,
      maxPrice: _currentRange.end < 5000 ? _currentRange.end : null,
      onSaleOnly: _onSaleOnly,
      inStockOnly: _inStockOnly,
      sort: _sort,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text('Filters',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(onPressed: _reset, child: const Text('Reset All')),
              ],
            ),
          ),
          const Divider(height: 1),

          // Filters
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Category
                if (widget.categories.isNotEmpty) ...[
                  const _FilterLabel('Category'),
                  Wrap(
                    spacing: 8,
                    children: widget.categories.map((cat) {
                      return ChoiceChip(
                        label: Text(cat.name),
                        selected: _category == cat.id,
                        onSelected: (_) =>
                            setState(() => _category =
                                _category == cat.id ? null : cat.id),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Gender
                const _FilterLabel('Gender'),
                Wrap(
                  spacing: 8,
                  children: _genders.map((g) {
                    return ChoiceChip(
                      label: Text(g[0].toUpperCase() + g.substring(1)),
                      selected: _gender == g,
                      onSelected: (_) =>
                          setState(() => _gender = _gender == g ? null : g),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Price range
                const _FilterLabel('Price Range'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rs ${_currentRange.start.toInt()}'),
                    Text('Rs ${_currentRange.end.toInt()}'),
                  ],
                ),
                RangeSlider(
                  values: _currentRange,
                  min: _rangeValues.start,
                  max: _rangeValues.end,
                  divisions: 50,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _currentRange = v),
                ),
                const SizedBox(height: 16),

                // Size
                const _FilterLabel('Size'),
                Wrap(
                  spacing: 8,
                  children: _sizes.map((s) {
                    return ChoiceChip(
                      label: Text(s),
                      selected: _size == s,
                      onSelected: (_) =>
                          setState(() => _size = _size == s ? null : s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Color
                const _FilterLabel('Color'),
                Wrap(
                  spacing: 8,
                  children: _colors.map((c) {
                    return ChoiceChip(
                      label: Text(c),
                      selected: _color == c,
                      onSelected: (_) =>
                          setState(() => _color = _color == c ? null : c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Toggle filters
                SwitchListTile(
                  title: const Text('On Sale Only'),
                  value: _onSaleOnly == true,
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _onSaleOnly = v ? true : null),
                ),
                SwitchListTile(
                  title: const Text('In Stock Only'),
                  value: _inStockOnly == true,
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) =>
                      setState(() => _inStockOnly = v ? true : null),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            child: CustomButton(text: 'Apply Filters', onPressed: _apply),
          ),
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  final String text;
  const _FilterLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }
}
