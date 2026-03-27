// Data models for the Family Marketplace app
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// バックエンドが返す相対パス（例: /uploads/items/abc.jpg）を
/// Image.network で使えるフルURLに変換する。
String _resolveUrl(String url) {
  if (!url.startsWith('/')) return url;
  if (kIsWeb) return 'http://localhost:3000$url';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000$url';
  return 'http://localhost:3000$url';
}

class User {
  final int id;
  final String accountId;
  final String name;

  const User({required this.id, required this.accountId, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      accountId: json['accountId'] as String,
      name: json['name'] as String,
    );
  }
}

class Group {
  final int id;
  final String name;
  final int ownerId;
  final DateTime createdAt;

  const Group({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as int,
      name: json['name'] as String,
      ownerId: json['ownerId'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ItemImage {
  final int id;
  final String imageUrl;
  final int order;

  const ItemImage({required this.id, required this.imageUrl, required this.order});

  factory ItemImage.fromJson(Map<String, dynamic> json) {
    return ItemImage(
      id: json['id'] as int,
      imageUrl: _resolveUrl(json['imageUrl'] as String),
      order: json['order'] as int,
    );
  }
}

class ItemCategory {
  final int id;
  final String name;

  const ItemCategory({required this.id, required this.name});

  factory ItemCategory.fromJson(Map<String, dynamic> json) {
    return ItemCategory(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class Item {
  final int id;
  final String title;
  final String? description;
  final ItemCategory category;
  final User seller;
  final String status;
  final List<String> deliveryMethods;
  final List<ItemImage> images;
  final DateTime createdAt;

  const Item({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.seller,
    required this.status,
    required this.deliveryMethods,
    required this.images,
    required this.createdAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: ItemCategory.fromJson(json['category'] as Map<String, dynamic>),
      seller: User.fromJson(json['seller'] as Map<String, dynamic>),
      status: json['status'] as String,
      deliveryMethods: (json['deliveryMethods'] as List<dynamic>).map((e) => e as String).toList(),
      images: (json['images'] as List<dynamic>)
          .map((e) => ItemImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String get deliveryMethodsDisplay {
    return deliveryMethods.map((m) {
      switch (m) {
        case 'HAND_DELIVERY':
          return '手渡し';
        case 'POSTAL':
          return '郵送';
        case 'COURIER':
          return '宅配便';
        case 'OTHER':
          return 'その他';
        default:
          return m;
      }
    }).join('、');
  }

  String get statusDisplay {
    switch (status) {
      case 'AVAILABLE':
        return '出品中';
      case 'IN_TRANSACTION':
        return '取引中';
      case 'TRANSFERRED':
        return '譲渡済';
      case 'DELETED':
        return '削除済';
      default:
        return status;
    }
  }
}

class ItemRequest {
  final int id;
  final int itemId;
  final User requester;
  final String status;
  final String? deliveryMethod;
  final DateTime createdAt;
  final DateTime? completedAt;

  const ItemRequest({
    required this.id,
    required this.itemId,
    required this.requester,
    required this.status,
    this.deliveryMethod,
    required this.createdAt,
    this.completedAt,
  });

  factory ItemRequest.fromJson(Map<String, dynamic> json) {
    return ItemRequest(
      id: json['id'] as int,
      itemId: json['itemId'] as int,
      requester: User.fromJson(json['requester'] as Map<String, dynamic>),
      status: json['status'] as String,
      deliveryMethod: json['deliveryMethod'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  String get deliveryMethodDisplay {
    switch (deliveryMethod) {
      case 'HAND_DELIVERY': return '手渡し';
      case 'POSTAL': return '郵送';
      case 'COURIER': return '宅配便';
      case 'OTHER': return 'その他';
      default: return deliveryMethod ?? '';
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'PENDING':
        return '申請中';
      case 'APPROVED':
        return '承認済';
      case 'DECLINED':
        return '断られた';
      case 'CANCELLED':
        return 'キャンセル';
      case 'COMPLETED':
        return '完了';
      default:
        return status;
    }
  }
}
