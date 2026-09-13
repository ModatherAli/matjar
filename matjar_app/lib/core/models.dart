import "package:intl/intl.dart";

/// Formats money as "$1,234.00".
String formatMoney(double amount) =>
    NumberFormat.currency(symbol: "\$", decimalDigits: 2).format(amount);

/// Parses Prisma Decimal money fields (serialized as JSON strings).
double parseMoney(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class Paged<T> {
  const Paged({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  final List<T> items;
  final int total;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  static Paged<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final pagination = json["pagination"] as Map<String, dynamic>?;
    return Paged<T>(
      items: (json["data"] as List<dynamic>? ?? [])
          .map((e) => parse(e as Map<String, dynamic>))
          .toList(),
      total: (pagination?["total"] as num?)?.toInt() ?? 0,
      page: (pagination?["page"] as num?)?.toInt() ?? 1,
      totalPages: (pagination?["totalPages"] as num?)?.toInt() ?? 1,
    );
  }
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.productCount = 0,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final int productCount;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json["id"] as String,
        name: json["name"] as String,
        slug: json["slug"] as String,
        description: json["description"] as String?,
        imageUrl: json["imageUrl"] as String?,
        productCount:
            ((json["_count"] as Map<String, dynamic>?)?["products"] as num?)?.toInt() ?? 0,
      );
}

class ProductImage {
  const ProductImage({required this.id, required this.url, this.position = 0});

  final String id;
  final String url;
  final int position;

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
        id: json["id"] as String,
        url: json["url"] as String,
        position: (json["position"] as num?)?.toInt() ?? 0,
      );
}

class Product {
  const Product({
    required this.id,
    required this.title,
    required this.slug,
    required this.price,
    required this.stockQty,
    required this.isActive,
    required this.images,
    this.description,
    this.compareAtPrice,
    this.sku,
    this.categoryName,
    this.categorySlug,
    this.ratingAverage,
    this.ratingCount,
  });

  final String id;
  final String title;
  final String slug;
  final String? description;
  final double price;
  final double? compareAtPrice;
  final String? sku;
  final int stockQty;
  final bool isActive;
  final String? categoryName;
  final String? categorySlug;
  final List<ProductImage> images;
  final double? ratingAverage;
  final int? ratingCount;

  bool get inStock => stockQty > 0;
  bool get isLowStock => inStock && stockQty <= 3;
  bool get hasDiscount =>
      compareAtPrice != null && compareAtPrice! > price && compareAtPrice! > 0;
  int? get discountPercent => hasDiscount
      ? (((compareAtPrice! - price) / compareAtPrice!) * 100).round()
      : null;
  String? get coverImage => images.isNotEmpty ? images.first.url : null;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json["id"] as String,
        title: json["title"] as String,
        slug: json["slug"] as String,
        description: json["description"] as String?,
        price: parseMoney(json["price"]),
        compareAtPrice: json["compareAtPrice"] == null
            ? null
            : parseMoney(json["compareAtPrice"]),
        sku: json["sku"] as String?,
        stockQty: (json["stockQty"] as num?)?.toInt() ?? 0,
        isActive: json["isActive"] as bool? ?? true,
        categoryName:
            (json["category"] as Map<String, dynamic>?)?["name"] as String?,
        categorySlug:
            (json["category"] as Map<String, dynamic>?)?["slug"] as String?,
        images: (json["images"] as List<dynamic>? ?? [])
            .map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
            .toList(),
        ratingAverage: json["rating"] is Map<String, dynamic>
            ? (json["rating"]["average"] as num?)?.toDouble()
            : null,
        ratingCount: json["rating"] is Map<String, dynamic>
            ? (json["rating"]["count"] as num?)?.toInt()
            : null,
      );
}

class Review {
  const Review({
    required this.id,
    required this.rating,
    required this.createdAt,
    required this.userId,
    required this.userName,
    this.comment,
  });

  final String id;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String userId;
  final String userName;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json["id"] as String,
        rating: (json["rating"] as num).toInt(),
        comment: json["comment"] as String?,
        createdAt: DateTime.parse(json["createdAt"] as String),
        userId: (json["user"] as Map<String, dynamic>)["id"] as String,
        userName: (json["user"] as Map<String, dynamic>)["name"] as String,
      );
}

class CartProduct {
  const CartProduct({
    required this.id,
    required this.title,
    required this.slug,
    required this.price,
    required this.stockQty,
    required this.isActive,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String slug;
  final double price;
  final int stockQty;
  final bool isActive;
  final String? imageUrl;

  factory CartProduct.fromJson(Map<String, dynamic> json) => CartProduct(
        id: json["id"] as String,
        title: json["title"] as String,
        slug: json["slug"] as String,
        price: parseMoney(json["price"]),
        stockQty: (json["stockQty"] as num?)?.toInt() ?? 0,
        isActive: json["isActive"] as bool? ?? true,
        imageUrl: (json["images"] as List<dynamic>? ?? []).isNotEmpty
            ? (json["images"].first as Map<String, dynamic>)["url"] as String?
            : null,
      );
}

class CartItem {
  const CartItem({required this.id, required this.quantity, required this.product});

  final String id;
  final int quantity;
  final CartProduct product;

  double get lineTotal => product.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json["id"] as String,
        quantity: (json["quantity"] as num).toInt(),
        product: CartProduct.fromJson(json["product"] as Map<String, dynamic>),
      );
}

class Cart {
  const Cart({required this.items, required this.subtotal, required this.itemCount});

  final List<CartItem> items;
  final double subtotal;
  final int itemCount;

  bool get isEmpty => items.isEmpty;

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        items: (json["items"] as List<dynamic>? ?? [])
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json["subtotal"] as num?)?.toDouble() ?? 0,
        itemCount: (json["itemCount"] as num?)?.toInt() ?? 0,
      );
}

class Address {
  const Address({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    required this.country,
    required this.isDefault,
    this.zip,
  });

  final String id;
  final String label;
  final String street;
  final String city;
  final String country;
  final String? zip;
  final bool isDefault;

  String get singleLine => "$street, $city, $country${zip == null ? "" : " $zip"}";

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json["id"] as String,
        label: json["label"] as String? ?? "home",
        street: json["street"] as String,
        city: json["city"] as String,
        country: json["country"] as String,
        zip: json["zip"] as String?,
        isDefault: json["isDefault"] as bool? ?? false,
      );
}

class ShippingAddress {
  const ShippingAddress({
    required this.label,
    required this.street,
    required this.city,
    required this.country,
    this.zip,
    this.recipientName,
  });

  final String label;
  final String street;
  final String city;
  final String country;
  final String? zip;
  final String? recipientName;

  String get singleLine => "$street, $city, $country${zip == null ? "" : " $zip"}";

  factory ShippingAddress.fromJson(Map<String, dynamic> json) => ShippingAddress(
        label: json["label"] as String? ?? "home",
        street: json["street"] as String? ?? "",
        city: json["city"] as String? ?? "",
        country: json["country"] as String? ?? "",
        zip: json["zip"] as String?,
        recipientName: json["recipientName"] as String?,
      );
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.title,
    required this.priceAtPurchase,
    required this.quantity,
  });

  final String id;
  final String title;
  final double priceAtPurchase;
  final int quantity;

  double get lineTotal => priceAtPurchase * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json["id"] as String,
        title: json["titleSnapshot"] as String? ??
            ((json["product"] as Map<String, dynamic>?)?["title"] as String? ?? ""),
        priceAtPurchase: parseMoney(json["priceAtPurchase"]),
        quantity: (json["quantity"] as num).toInt(),
      );
}

class Order {
  const Order({
    required this.id,
    required this.status,
    required this.paymentStatus,
    required this.subtotal,
    required this.shippingCost,
    required this.total,
    required this.createdAt,
    required this.items,
    required this.shippingAddress,
    this.customerName,
    this.customerEmail,
  });

  final String id;
  final String status;
  final String paymentStatus;
  final double subtotal;
  final double shippingCost;
  final double total;
  final DateTime createdAt;
  final List<OrderItem> items;
  final ShippingAddress shippingAddress;
  final String? customerName;
  final String? customerEmail;

  bool get canCancel => status == "PENDING";

  String get statusLabel {
    switch (status) {
      case "PENDING":
        return "Pending";
      case "PAID":
        return "Paid";
      case "SHIPPED":
        return "Shipped";
      case "DELIVERED":
        return "Delivered";
      case "CANCELLED":
        return "Cancelled";
      default:
        return status;
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json["id"] as String,
        status: json["status"] as String,
        paymentStatus: json["paymentStatus"] as String? ?? "UNPAID",
        subtotal: parseMoney(json["subtotal"]),
        shippingCost: parseMoney(json["shippingCost"]),
        total: parseMoney(json["total"]),
        createdAt: DateTime.parse(json["createdAt"] as String),
        items: (json["items"] as List<dynamic>? ?? [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        shippingAddress: ShippingAddress.fromJson(
          (json["shippingAddress"] as Map<String, dynamic>?) ?? {},
        ),
        customerName: (json["user"] as Map<String, dynamic>?)?["name"] as String?,
        customerEmail: (json["user"] as Map<String, dynamic>?)?["email"] as String?,
      );
}

class AdminUserAccount {
  const AdminUserAccount({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.phone,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final String? phone;

  factory AdminUserAccount.fromJson(Map<String, dynamic> json) => AdminUserAccount(
        id: json["id"] as String,
        email: json["email"] as String,
        name: json["name"] as String,
        role: json["role"] as String,
        isActive: json["isActive"] as bool? ?? true,
        createdAt: DateTime.parse(json["createdAt"] as String),
        phone: json["phone"] as String?,
      );
}

class LowStockItem {
  const LowStockItem({
    required this.id,
    required this.title,
    required this.sku,
    required this.stockQty,
  });

  final String id;
  final String title;
  final String sku;
  final int stockQty;

  factory LowStockItem.fromJson(Map<String, dynamic> json) => LowStockItem(
        id: json["id"] as String,
        title: json["title"] as String,
        sku: json["sku"] as String? ?? "",
        stockQty: (json["stockQty"] as num?)?.toInt() ?? 0,
      );
}

class RecentOrder {
  const RecentOrder({
    required this.id,
    required this.total,
    required this.status,
    required this.createdAt,
    this.userName,
    this.userEmail,
  });

  final String id;
  final double total;
  final String status;
  final DateTime createdAt;
  final String? userName;
  final String? userEmail;

  factory RecentOrder.fromJson(Map<String, dynamic> json) => RecentOrder(
        id: json["id"] as String,
        total: parseMoney(json["total"]),
        status: json["status"] as String,
        createdAt: DateTime.parse(json["createdAt"] as String),
        userName: (json["user"] as Map<String, dynamic>?)?["name"] as String?,
        userEmail: (json["user"] as Map<String, dynamic>?)?["email"] as String?,
      );
}

class Dashboard {
  const Dashboard({
    required this.revenue,
    required this.totalUsers,
    required this.totalProducts,
    required this.totalOrders,
    required this.ordersByStatus,
    required this.lowStock,
    required this.recentOrders,
  });

  final double revenue;
  final int totalUsers;
  final int totalProducts;
  final int totalOrders;
  final Map<String, int> ordersByStatus;
  final List<LowStockItem> lowStock;
  final List<RecentOrder> recentOrders;

  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
        revenue: (json["revenue"] as num?)?.toDouble() ?? 0,
        totalUsers: (json["totalUsers"] as num?)?.toInt() ?? 0,
        totalProducts: (json["totalProducts"] as num?)?.toInt() ?? 0,
        totalOrders: (json["totalOrders"] as num?)?.toInt() ?? 0,
        ordersByStatus: (json["ordersByStatus"] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        lowStock: (json["lowStock"] as List<dynamic>? ?? [])
            .map((e) => LowStockItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentOrders: (json["recentOrders"] as List<dynamic>? ?? [])
            .map((e) => RecentOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}