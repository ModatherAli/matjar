import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/models.dart";
import "../../core/widgets.dart";
import "catalog_repository.dart";
import "product_card.dart";

/// Catalog browsing: debounced search, category chips, sorting and
/// infinite 2-column grid pagination.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  late String _category = widget.initialCategory ?? "";
  String _search = "";
  String _sort = "newest";
  final _items = <Product>[];
  bool _hasMore = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 400) {
      _load(reset: false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search = value.trim();
      _load(reset: true);
    });
  }

  Future<void> _load({required bool reset}) async {
    if (_loading) {
      return;
    }
    if (!reset && !_hasMore) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _hasMore = true;
      }
    });
    final page = reset ? 1 : (_items.length / 12).floor() + 1;
    try {
      final result = await ref.read(catalogRepositoryProvider).listProducts(
            ProductQuery(
              search: _search.isEmpty ? null : _search,
              categorySlug: _category.isEmpty ? null : _category,
              sort: _sort,
              page: page,
            ),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        if (reset) {
          _items.clear();
        }
        _items.addAll(result.items);
        _hasMore = result.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
        if (reset) {
          _items.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("The Atelier"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: "Search the collection…",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: categories.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
              data: (list) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _chip("All", _category.isEmpty, () {
                    setState(() => _category = "");
                    _load(reset: true);
                  }),
                  for (final category in list)
                    _chip(category.name, _category == category.slug, () {
                      setState(() => _category = category.slug);
                      _load(reset: true);
                    }),
                ],
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
                  "newest": "Newest",
                  "price_asc": "Price ↑",
                  "price_desc": "Price ↓",
                }.entries)
                  _chip(entry.value, _sort == entry.key, () {
                    setState(() => _sort = entry.key);
                    _load(reset: true);
                  }),
              ],
            ),
          ),
          Expanded(
            child: _error != null && _items.isEmpty
                ? ErrorView(
                    message: _error!,
                    onRetry: () => _load(reset: true),
                  )
                : _items.isEmpty && _loading
                    ? const LoadingGrid(itemCount: 6)
                    : _items.isEmpty
                        ? const EmptyView(
                            icon: Icons.search_off,
                            message: "Nothing matches your search.",
                          )
                        : GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.66,
                            ),
                            itemCount: _items.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _items.length) {
                                return Center(
                                  child: _loading
                                      ? const CircularProgressIndicator(
                                          strokeWidth: 2)
                                      : Text(
                                          "Pull up for more",
                                          style: theme.textTheme.labelSmall,
                                        ),
                                );
                              }
                              return ProductCard(product: _items[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}