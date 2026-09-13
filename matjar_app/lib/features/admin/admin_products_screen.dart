import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:image_picker/image_picker.dart";

import "../../core/models.dart";
import "../../core/theme.dart";
import "../../core/widgets.dart";
import "../catalog/catalog_repository.dart";
import "admin_repository.dart";

/// Admin product management: search, active filter, create/edit/delete,
/// and image upload via the device gallery.
class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final _search = TextEditingController();
  String _searchValue = "";
  String _activeFilter = "all";
  String _key = "|all|newest|1";

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _rebuildKey() {
    _key = "$_searchValue|$_activeFilter|newest|1";
    ref.invalidate(adminProductsProvider(_key));
  }

  Future<void> _openProductForm({Product? product}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _ProductFormDialog(product: product),
    );
    if (saved == true) {
      _rebuildKey();
    }
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete ${product.title}?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      final softDeleted =
          await ref.read(adminRepositoryProvider).deleteProduct(product.id);
      _rebuildKey();
      if (mounted) {
        showError(
          context,
          softDeleted ? "Deactivated (has order history)." : "Product deleted.",
        );
      }
    } catch (e) {
      if (mounted) {
        showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(adminProductsProvider(_key));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Products")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductForm(),
        label: const Text("New product"),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              controller: _search,
              onChanged: (value) {
                _searchValue = value.trim();
                _rebuildKey();
              },
              decoration: const InputDecoration(
                hintText: "Search products…",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final entry in const {
                  "all": "All",
                  "true": "Active",
                  "false": "Inactive",
                }.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: _activeFilter == entry.key,
                      onSelected: (_) {
                        setState(() => _activeFilter = entry.key);
                        _rebuildKey();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: page.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () =>
                    ref.invalidate(adminProductsProvider(_key)),
              ),
              data: (result) => ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: result.items.length,
                itemBuilder: (context, index) {
                  final product = result.items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(
                        product.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "${formatMoney(product.price)} · "
                        "stock ${product.stockQty} · "
                        "${product.isActive ? "active" : "inactive"}",
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == "images") {
                            _openImageManager(product);
                          } else if (value == "edit") {
                            _openProductForm(product: product);
                          } else if (value == "toggle") {
                            _toggleActive(product);
                          } else if (value == "delete") {
                            _confirmDelete(product);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: "images",
                            child: Text("Images"),
                          ),
                          PopupMenuItem(
                            value: "edit",
                            child: Text("Edit"),
                          ),
                          PopupMenuItem(
                            value: "toggle",
                            child: Text("Toggle active"),
                          ),
                          PopupMenuItem(
                            value: "delete",
                            child: Text("Delete"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(Product product) async {
    try {
      await ref.read(adminRepositoryProvider).updateProduct(
            product.id,
            isActive: !product.isActive,
          );
      _rebuildKey();
    } catch (e) {
      if (mounted) {
        showError(context, e.toString());
      }
    }
  }

  Future<void> _openImageManager(Product product) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ImageManagerDialog(product: product),
    );
    if (mounted) {
      _rebuildKey();
    }
  }
}

class _ImageManagerDialog extends ConsumerStatefulWidget {
  const _ImageManagerDialog({required this.product});

  final Product product;

  @override
  ConsumerState<_ImageManagerDialog> createState() =>
      _ImageManagerDialogState();
}

class _ImageManagerDialogState extends ConsumerState<_ImageManagerDialog> {
  List<ProductImage> _images = [];
  bool _uploading = false;

  Product get product => widget.product;

  @override
  void initState() {
    super.initState();
    _images = List<ProductImage>.from(product.images);
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty || !mounted) {
      return;
    }
    setState(() => _uploading = true);
    try {
      final uploaded = await ref.read(adminRepositoryProvider).addImages(
            product.id,
            files.map((f) => f.path).toList(),
          );
      if (mounted) {
        setState(() => _images.addAll(uploaded));
      }
    } catch (e) {
      if (mounted) {
        showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _removeImage(ProductImage image) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .deleteImage(product.id, image.id);
      if (mounted) {
        setState(() => _images.removeWhere((i) => i.id == image.id));
      }
    } catch (e) {
      if (mounted) {
        showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text("Images · ${product.title}"),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_images.isEmpty)
              const Text("No images yet.")
            else
              for (final image in _images)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text("Image #${image.position}", maxLines: 1),
                  subtitle: Text(
                    image.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: "Delete image",
                    onPressed: () => _removeImage(image),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
            const SizedBox(height: 12),
            Text(
              "Upload from the device gallery (max 5 per request).",
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Done"),
        ),
        FilledButton(
          onPressed: _uploading ? null : _pickAndUpload,
          child: _uploading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black,
                  ),
                )
              : const Text("Upload"),
        ),
      ],
    );
  }
}

class _ProductFormDialog extends ConsumerStatefulWidget {
  const _ProductFormDialog({this.product});

  final Product? product;

  @override
  ConsumerState<_ProductFormDialog> createState() =>
      _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<_ProductFormDialog> {
  late final _title = TextEditingController(text: widget.product?.title);
  late final _description =
      TextEditingController(text: widget.product?.description);
  late final _price = TextEditingController(
    text: widget.product == null ? "" : "${widget.product!.price}",
  );
  late final _compare = TextEditingController(
    text: widget.product?.compareAtPrice == null
        ? ""
        : "${widget.product!.compareAtPrice}",
  );
  late final _sku = TextEditingController(text: widget.product?.sku);
  late final _stock =
      TextEditingController(text: "${widget.product?.stockQty ?? 0}");
  late bool _isActive = widget.product?.isActive ?? true;
  String? _categoryId;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _compare.dispose();
    _sku.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _categoryId == null) {
      showError(context, "Title and category are required.");
      return;
    }
    final price = double.tryParse(_price.text.trim());
    if (price == null || price <= 0) {
      showError(context, "Enter a valid positive price.");
      return;
    }
    final stock = int.tryParse(_stock.text.trim());
    if (stock == null || stock < 0) {
      showError(context, "Enter a valid stock quantity.");
      return;
    }
    final compare = _compare.text.trim().isEmpty
        ? null
        : double.tryParse(_compare.text.trim());
    setState(() => _saving = true);
    final repo = ref.read(adminRepositoryProvider);
    try {
      if (widget.product == null) {
        await repo.createProduct(
          title: _title.text.trim(),
          price: price,
          categoryId: _categoryId!,
          description: _description.text.trim(),
          compareAtPrice: compare,
          sku: _sku.text.trim(),
          stockQty: stock,
          isActive: _isActive,
        );
      } else {
        await repo.updateProduct(
          widget.product!.id,
          title: _title.text.trim(),
          price: price,
          categoryId: _categoryId!,
          description: _description.text.trim(),
          compareAtPrice: compare,
          clearCompareAtPrice: compare == null,
          sku: _sku.text.trim().isEmpty ? null : _sku.text.trim(),
          stockQty: stock,
          isActive: _isActive,
        );
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    return AlertDialog(
      title: Text(widget.product == null ? "New product" : "Edit product"),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "Price"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _compare,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: "Compare at"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sku,
                      decoration: const InputDecoration(labelText: "SKU"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Stock qty"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              categories.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(e.toString()),
                data: (list) {
                  if (list.isEmpty) {
                    return const Text("No categories. Create one first.");
                  }
                  _categoryId ??= widget.product?.categorySlug != null
                      ? list
                          .firstWhere(
                            (c) => c.slug == widget.product!.categorySlug,
                            orElse: () => list.first,
                          )
                          .id
                      : list.first.id;
                  return DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: "Category"),
                    items: [
                      for (final category in list)
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: (value) => _categoryId = value,
                  );
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Active"),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black,
                  ),
                )
              : Text(widget.product == null ? "Create" : "Update"),
        ),
      ],
    );
  }
}

/// Admin category management: create, rename, delete.
class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState
    extends ConsumerState<AdminCategoriesScreen> {
  Future<void> _refresh() async {
    ref.invalidate(categoriesProvider);
  }

  Future<void> _openForm({Category? category}) async {
    final name = TextEditingController(text: category?.name);
    final description = TextEditingController(text: category?.description);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? "New category" : "Edit category"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: description,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Description"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) {
                Navigator.pop(context, false);
                return;
              }
              final repo = ref.read(adminRepositoryProvider);
              try {
                if (category == null) {
                  await repo.createCategory(
                    name: name.text.trim(),
                    description: description.text.trim(),
                  );
                } else {
                  await repo.updateCategory(
                    category.id,
                    name: name.text.trim(),
                    description: description.text.trim(),
                  );
                }
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              } catch (e) {
                if (context.mounted) {
                  showError(context, e.toString());
                }
              }
            },
            child: Text(category == null ? "Create" : "Update"),
          ),
        ],
      ),
    );
    if (saved == true) {
      _refresh();
    }
  }

  Future<void> _delete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete ${category.name}?"),
        content: const Text("Only empty leaf categories can be deleted."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref.read(adminRepositoryProvider).deleteCategory(category.id);
      _refresh();
    } catch (e) {
      if (mounted) {
        showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Categories")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        label: const Text("New category"),
        icon: const Icon(Icons.add),
      ),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyView(
              icon: Icons.category_outlined,
              message: "No categories yet.",
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final category = list[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    category.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Slug ${category.slug} · "
                    "${category.productCount} products",
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "edit") {
                        _openForm(category: category);
                      } else if (value == "delete") {
                        _delete(category);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: "edit", child: Text("Edit")),
                      PopupMenuItem(value: "delete", child: Text("Delete")),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Admin fulfillment queue: all orders with status filters.
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String _status = "ALL";

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(adminOrdersProvider(_status));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Orders")),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final value in const [
                  "ALL",
                  "PENDING",
                  "PAID",
                  "SHIPPED",
                  "DELIVERED",
                  "CANCELLED",
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(value.toLowerCase()),
                      selected: _status == value,
                      onSelected: (_) => setState(() => _status = value),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: orders.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(adminOrdersProvider(_status)),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyView(
                    icon: Icons.receipt_long_outlined,
                    message: "No orders in this queue.",
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: page.items.length,
                  itemBuilder: (context, index) {
                    final order = page.items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        onTap: () => context.push("/orders/${order.id}"),
                        title: Text(
                          "#${order.id.substring(0, 8)} · "
                          "${order.customerName ?? order.customerEmail ?? "guest"}",
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          "${order.status.toLowerCase()} · "
                          "${order.items.length} item(s)",
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Text(
                          formatMoney(order.total),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: MatjarColors.gold,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}