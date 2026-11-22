import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/core/utils/money.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/vendor/providers/vendor_provider.dart';
import 'package:college_canteen/features/vendor/services/vendor_id.dart';
import 'package:college_canteen/features/vendor/services/vendor_validators.dart';

class VendorItemsTab extends StatelessWidget {
  final String? vendorId;

  const VendorItemsTab({super.key, this.vendorId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
        child: Consumer<VendorProvider>(
          builder: (context, provider, child) {
            final items = provider.vendorItems;
            final lastError = provider.lastError;

            return Stack(
              children: [
                if (items.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.restaurant_menu_outlined,
                            size: 64,
                            color: AppTheme.primaryColor.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No menu items yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap "+ Add item" below to list your first food or stationery item.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 88),
                    itemCount: items.length + (lastError != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (lastError != null && index == 0) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 20,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  lastError,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                color: Colors.red.shade700,
                                onPressed: () => provider.clearLastError(),
                              ),
                            ],
                          ),
                        );
                      }

                      final itemIndex =
                          lastError != null ? index - 1 : index;
                      final item = items[itemIndex];
                      return _VendorItemCard(
                        key: ValueKey(item.id),
                        item: item,
                      );
                    },
                  ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () => _openItemForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add item'),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openItemForm(BuildContext context, [MenuItem? item]) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _ItemFormDialog(item: item),
    );
  }
}

class _VendorItemCard extends StatelessWidget {
  final MenuItem item;

  const _VendorItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: const Color(0xFFFFE0B2),
                    child: item.imageUrl.isNotEmpty
                        ? Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, _, __) => const Center(
                              child: Icon(
                                Icons.restaurant,
                                color: AppTheme.primaryColor,
                                size: 28,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.restaurant,
                              color: AppTheme.primaryColor,
                              size: 28,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.category.displayName} • ${item.prepLabel}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (item.hasDiscount) ...[
                            Text(
                              formatRupees(item.originalPrice!),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            formatRupees(item.price),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: item.hasDiscount
                                  ? AppTheme.primaryColor
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          if (item.hasDiscount) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.red.shade300,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '${item.discountPercent}% OFF',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppTheme.textSecondary,
                  ),
                  onSelected: (action) => _handleAction(context, action),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    if (item.hasDiscount)
                      const PopupMenuItem(
                        value: 'remove_discount',
                        child: Row(
                          children: [
                            Icon(
                              Icons.money_off_outlined,
                              size: 20,
                              color: AppTheme.textSecondary,
                            ),
                            SizedBox(width: 10),
                            Text('Remove Discount'),
                          ],
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'apply_discount',
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 20,
                              color: AppTheme.textSecondary,
                            ),
                            SizedBox(width: 10),
                            Text('Apply Discount'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'custom_message',
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 20,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(width: 10),
                          Text('Edit Custom Message'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item.customCustomerMessage != null &&
                    item.customCustomerMessage!.trim().isNotEmpty)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.campaign_outlined,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.customCustomerMessage!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.isAvailable ? 'Available' : 'Sold out',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: item.isAvailable
                            ? AppTheme.pureVegGreen
                            : Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: item.isAvailable,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) {
                        context.read<VendorProvider>().setAvailability(item, val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    final provider = context.read<VendorProvider>();
    switch (action) {
      case 'edit':
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => _ItemFormDialog(item: item),
        );
        break;
      case 'apply_discount':
        showDialog<void>(
          context: context,
          builder: (dialogCtx) => _DiscountDialog(item: item),
        );
        break;
      case 'remove_discount':
        provider.removeDiscount(item);
        break;
      case 'custom_message':
        showDialog<void>(
          context: context,
          builder: (dialogCtx) => _CustomMessageDialog(item: item),
        );
        break;
      case 'delete':
        showDialog<void>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: Text('Delete ${item.name}?'),
            content: const Text(
              'Are you sure you want to permanently delete this item from your menu?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  provider.deleteItem(item.id);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        break;
    }
  }
}

class _ItemFormDialog extends StatefulWidget {
  final MenuItem? item;

  const _ItemFormDialog({this.item});

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  late final TextEditingController _nameController;
  late FoodCategory _category;
  late final TextEditingController _priceController;
  late final TextEditingController _prepMinController;
  late final TextEditingController _prepMaxController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _descController;

  String? _nameError;
  String? _priceError;
  String? _prepError;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _category = item?.category ?? FoodCategory.snacks;
    _priceController =
        TextEditingController(text: item != null ? item.price.toString() : '');
    _prepMinController =
        TextEditingController(text: item?.prepMinMinutes.toString() ?? '5');
    _prepMaxController =
        TextEditingController(text: item?.prepMaxMinutes.toString() ?? '15');
    _imageUrlController = TextEditingController(text: item?.imageUrl ?? '');
    _descController = TextEditingController(text: item?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _prepMinController.dispose();
    _prepMaxController.dispose();
    _imageUrlController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameController.text.trim();
    final nameErr = validateItemName(name);

    final priceInt = int.tryParse(_priceController.text.trim());
    final priceErr = validatePrice(priceInt);

    final prepMin = int.tryParse(_prepMinController.text.trim()) ?? 0;
    final prepMax = int.tryParse(_prepMaxController.text.trim()) ?? 0;
    final prepErr = validatePrep(min: prepMin, max: prepMax);

    if (nameErr != null || priceErr != null || prepErr != null) {
      setState(() {
        _nameError = nameErr;
        _priceError = priceErr;
        _prepError = prepErr;
      });
      return;
    }

    final provider = context.read<VendorProvider>();
    const defaultPlaceholder =
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=600&q=80';
    final imageUrl = _imageUrlController.text.trim().isEmpty
        ? defaultPlaceholder
        : _imageUrlController.text.trim();

    if (widget.item == null) {
      final generatedId =
          '${slugifyVendorName(name)}-${DateTime.now().millisecondsSinceEpoch % 100000}';
      final newItem = MenuItem(
        id: generatedId,
        name: name,
        category: _category,
        description: _descController.text.trim(),
        vendorId: provider.vendorId,
        vendorName: provider.profile?.businessName ?? AppConfig.defaultVendorName,
        price: priceInt!,
        prepMinMinutes: prepMin,
        prepMaxMinutes: prepMax,
        imageUrl: imageUrl,
        isAvailable: true,
        rating: 0.0,
        ratingCount: 0,
      );
      await provider.saveItem(newItem);
    } else {
      final updatedItem = widget.item!.copyWith(
        name: name,
        category: _category,
        description: _descController.text.trim(),
        price: priceInt!,
        prepMinMinutes: prepMin,
        prepMaxMinutes: prepMax,
        imageUrl: imageUrl,
      );
      await provider.saveItem(updatedItem);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Menu Item' : 'Add New Item'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g. Masala Dosa',
                  errorText: _nameError,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_nameError != null) {
                    setState(() => _nameError = null);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FoodCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: FoodCategory.values
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (cat) {
                  if (cat != null) setState(() => _category = cat);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price (₹) *',
                  hintText: 'e.g. 50',
                  errorText: _priceError,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_priceError != null) {
                    setState(() => _priceError = null);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _prepMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prep Min (mins) *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        if (_prepError != null) {
                          setState(() => _prepError = null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _prepMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prep Max (mins) *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        if (_prepError != null) {
                          setState(() => _prepError = null);
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (_prepError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _prepError!,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _imageUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                  hintText: 'Leave empty for default image',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief description of ingredients or preparation',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save Changes' : 'Add Item'),
        ),
      ],
    );
  }
}

class _DiscountDialog extends StatefulWidget {
  final MenuItem item;

  const _DiscountDialog({required this.item});

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() async {
    final newPrice = int.tryParse(_controller.text.trim()) ?? 0;
    final err = validateDiscount(
      originalPrice: widget.item.price,
      discountedPrice: newPrice,
    );

    if (err != null) {
      setState(() => _error = err);
      return;
    }

    final provider = context.read<VendorProvider>();
    await provider.applyDiscount(widget.item, newPrice);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Apply Discount: ${widget.item.name}'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current price: ${formatRupees(widget.item.price)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'New Discounted Price (₹) *',
                hintText: 'e.g. ${(widget.item.price * 0.8).round()}',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_error != null) {
                  setState(() => _error = null);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _apply,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _CustomMessageDialog extends StatefulWidget {
  final MenuItem item;

  const _CustomMessageDialog({required this.item});

  @override
  State<_CustomMessageDialog> createState() => _CustomMessageDialogState();
}

class _CustomMessageDialogState extends State<_CustomMessageDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.item.customCustomerMessage ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() async {
    final msg = _controller.text.trim();
    final err = validateCustomMessage(msg);

    if (err != null) {
      setState(() => _error = err);
      return;
    }

    final provider = context.read<VendorProvider>();
    await provider.setCustomMessage(widget.item, msg);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _clear() async {
    final provider = context.read<VendorProvider>();
    await provider.setCustomMessage(widget.item, null);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Custom Message: ${widget.item.name}'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Show a short highlight badge to customers (e.g. "Chef\'s Special", "Fresh Batch")',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLength: 60,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Badge Message (≤ 60 chars)',
                hintText: 'e.g. Hot & Fresh',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_error != null) {
                  setState(() => _error = null);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        if (widget.item.customCustomerMessage != null &&
            widget.item.customCustomerMessage!.isNotEmpty)
          TextButton(
            onPressed: _clear,
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Clear'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
