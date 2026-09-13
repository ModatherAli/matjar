import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../core/models.dart";
import "../../core/widgets.dart";
import "address_repository.dart";
import "cart_repository.dart";
import "order_repository.dart";

/// Checkout: pick or add a shipping address, then place the order.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? _selectedAddressId;
  bool _showAddForm = false;
  bool _placing = false;

  final _label = TextEditingController(text: "Home");
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _zip = TextEditingController();
  final _country = TextEditingController(text: "USA");

  @override
  void dispose() {
    _label.dispose();
    _street.dispose();
    _city.dispose();
    _zip.dispose();
    _country.dispose();
    super.dispose();
  }

  bool get _formValid =>
      _street.text.trim().isNotEmpty &&
      _city.text.trim().isNotEmpty &&
      _zip.text.trim().isNotEmpty &&
      _country.text.trim().isNotEmpty;

  Future<void> _addAddress() async {
    if (!_formValid) {
      return;
    }
    try {
      final address = await ref.read(addressRepositoryProvider).create(
            label: _label.text.trim(),
            street: _street.text.trim(),
            city: _city.text.trim(),
            zip: _zip.text.trim(),
            country: _country.text.trim(),
          );
      ref.invalidate(addressesProvider);
      if (mounted) {
        setState(() {
          _selectedAddressId = address.id;
          _showAddForm = false;
          _street.clear();
          _city.clear();
          _zip.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        showError(context, e.toString());
      }
    }
  }

  Future<void> _deleteAddress(String id) async {
    try {
      await ref.read(addressRepositoryProvider).delete(id);
      ref.invalidate(addressesProvider);
      if (mounted && _selectedAddressId == id) {
        setState(() => _selectedAddressId = null);
      }
    } catch (e) {
      if (mounted) {
        showError(context, e.toString());
      }
    }
  }

  Future<void> _placeOrder() async {
    final cart = ref.read(cartProvider).value;
    if (cart == null || cart.items.isEmpty) {
      return;
    }
    if (_selectedAddressId == null) {
      showError(context, "Pick a shipping address first.");
      return;
    }
    setState(() => _placing = true);
    try {
      final order = await ref
          .read(orderRepositoryProvider)
          .checkout(addressId: _selectedAddressId!);
      ref.invalidate(cartProvider);
      ref.invalidate(ordersProvider("ALL"));
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Order placed"),
            content: Text(
              "Thank you! Order #${order.id.substring(0, 8)} is confirmed.",
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go("/orders");
                },
                child: const Text("View orders"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _placing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final addressesAsync = ref.watch(addressesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(cartProvider),
        ),
        data: (cart) {
          if (cart.items.isEmpty) {
            return const EmptyView(
              icon: Icons.shopping_bag_outlined,
              message: "Your bag is empty.",
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SectionHeader(eyebrow: "Delivery", title: "Shipping address"),
              const SizedBox(height: 12),
              addressesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(addressesProvider),
                ),
                data: (addresses) {
                  if (addresses.isEmpty && !_showAddForm) {
                    return Column(
                      children: [
                        const Text("Add a shipping address to continue."),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => setState(() => _showAddForm = true),
                          child: const Text("Add address"),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (final address in addresses)
                        Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () => setState(
                              () => _selectedAddressId = address.id,
                            ),
                            leading: Radio<String>(
                              value: address.id,
                              groupValue: _selectedAddressId,
                              onChanged: (value) =>
                                  setState(() => _selectedAddressId = value),
                            ),
                            title: Text(address.singleLine),
                            subtitle: Text("Label: ${address.label}"),
                            trailing: IconButton(
                              tooltip: "Delete address",
                              onPressed: () => _deleteAddress(address.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _showAddForm = !_showAddForm),
                        icon: Icon(
                          _showAddForm ? Icons.close : Icons.add_location_alt,
                        ),
                        label: Text(_showAddForm ? "Hide form" : "Add address"),
                      ),
                    ],
                  );
                },
              ),
              if (_showAddForm) ...[
                const SizedBox(height: 10),
                _field(_label, "Label (Home, Office…)"),
                _field(_street, "Street address"),
                _field(_city, "City"),
                _field(_zip, "ZIP code"),
                _field(_country, "Country"),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _formValid ? _addAddress : null,
                  child: const Text("Save address"),
                ),
              ],
              const SizedBox(height: 24),
              SectionHeader(eyebrow: "Summary", title: "Your bag"),
              const SizedBox(height: 8),
              for (final item in cart.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(item.product.title),
                  subtitle: Text("Qty ${item.quantity}"),
                  trailing: Text(formatMoney(item.lineTotal)),
                ),
              const Divider(),
              Row(
                children: [
                  Text(
                    "Total",
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  PriceText(cart.subtotal),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _placing ? null : _placeOrder,
                child: _placing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : const Text("Place Order"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: hint),
      ),
    );
  }
}