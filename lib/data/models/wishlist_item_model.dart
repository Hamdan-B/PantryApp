class WishlistItemModel {
  final String? id;
  final String userId;
  final String itemName;
  final String category;
  final DateTime createdAt;

  WishlistItemModel({
    this.id,
    required this.userId,
    required this.itemName,
    required this.category,
    required this.createdAt,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      itemName: json['item_name'] as String,
      category: json['category'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'user_id': userId,
      'item_name': itemName,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
    if (id != null) {
      json['id'] = id!;
    }
    return json;
  }

  WishlistItemModel copyWith({
    String? id,
    String? userId,
    String? itemName,
    String? category,
    DateTime? createdAt,
  }) {
    return WishlistItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
