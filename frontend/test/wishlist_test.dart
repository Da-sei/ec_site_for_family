import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/models.dart';
import 'package:frontend/features/wishlist/wishlist_state.dart';
import 'package:frontend/features/wishlist/wishlist_provider.dart';

/// テスト用 Dio HTTP アダプター
class _MockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) _handler;
  _MockAdapter(this._handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      _handler(options);

  @override
  void close({bool force = false}) {}
}

Dio _makeDio(Future<ResponseBody> Function(RequestOptions) handler) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.httpClientAdapter = _MockAdapter(handler);
  return dio;
}

/// テスト用サンプルアイテム JSON
const _sampleItemJson = {
  'id': 1,
  'title': '掃除機',
  'description': null,
  'groupId': 1,
  'requesterId': 1,
  'requester': {'id': 1, 'accountId': 'user1', 'name': '山田'},
  'createdAt': '2026-03-27T00:00:00.000Z',
  'updatedAt': '2026-03-27T00:00:00.000Z',
};

ResponseBody _jsonResponse(Object data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  // ─────────────────────────────────────────
  // WishlistItem.fromJson
  // ─────────────────────────────────────────
  group('WishlistItem.fromJson', () {
    test('正常系: 全フィールドをパースできる', () {
      final json = {
        'id': 1,
        'title': '掃除機',
        'description': 'コードレスタイプ希望',
        'groupId': 2,
        'requesterId': 3,
        'requester': {'id': 3, 'accountId': 'user001', 'name': '田中'},
        'createdAt': '2026-03-27T00:00:00.000Z',
        'updatedAt': '2026-03-27T12:00:00.000Z',
      };

      final item = WishlistItem.fromJson(json);

      expect(item.id, 1);
      expect(item.title, '掃除機');
      expect(item.description, 'コードレスタイプ希望');
      expect(item.groupId, 2);
      expect(item.requesterId, 3);
      expect(item.requester.accountId, 'user001');
      expect(item.requester.name, '田中');
      expect(item.createdAt, DateTime.parse('2026-03-27T00:00:00.000Z'));
      expect(item.updatedAt, DateTime.parse('2026-03-27T12:00:00.000Z'));
    });

    test('description=null のケース', () {
      final json = {
        'id': 2,
        'title': 'テレビ',
        'description': null,
        'groupId': 1,
        'requesterId': 5,
        'requester': {'id': 5, 'accountId': 'user002', 'name': '鈴木'},
        'createdAt': '2026-03-27T00:00:00.000Z',
        'updatedAt': '2026-03-27T00:00:00.000Z',
      };

      final item = WishlistItem.fromJson(json);

      expect(item.description, isNull);
    });
  });

  // ─────────────────────────────────────────
  // WishlistState.copyWith
  // ─────────────────────────────────────────
  group('WishlistState.copyWith', () {
    test('clearError=true でエラーがクリアされる', () {
      const state = WishlistState(errorMessage: 'エラーあり');
      final cleared = state.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });

    test('clearError=false (デフォルト) ではエラーが維持される', () {
      const state = WishlistState(errorMessage: 'エラーあり');
      final noChange = state.copyWith();
      expect(noChange.errorMessage, 'エラーあり');
    });

    test('isSubmitting を更新できる', () {
      const state = WishlistState();
      final submitting = state.copyWith(isSubmitting: true);
      expect(submitting.isSubmitting, true);
    });
  });

  // ─────────────────────────────────────────
  // WishlistNotifier
  // ─────────────────────────────────────────
  group('WishlistNotifier', () {
    test('groupId が null のとき loadWishlistItems を呼んでも API を呼ばない', () async {
      var apiCalled = false;
      final dio = _makeDio((_) async {
        apiCalled = true;
        return _jsonResponse([]);
      });

      final notifier = WishlistNotifier(dio);
      // setGroupId を呼ばず _groupId は null のまま
      await notifier.loadWishlistItems();

      expect(apiCalled, false);
      expect(notifier.state.items, isEmpty);
    });

    test('loadWishlistItems 成功時にステートが更新される', () async {
      final dio = _makeDio((_) async => _jsonResponse([_sampleItemJson]));

      final notifier = WishlistNotifier(dio);
      notifier.setGroupId(1); // _groupId をセット
      await notifier.loadWishlistItems(); // 直接 await でロード完了を保証

      expect(notifier.state.isLoading, false);
      expect(notifier.state.items.length, 1);
      expect(notifier.state.items.first.title, '掃除機');
    });

    test('createWishlistItem 成功時に true が返り items が更新される', () async {
      // HTTP メソッドで POST / GET を振り分け
      final dio = _makeDio((options) async {
        if (options.method == 'POST') {
          return _jsonResponse(_sampleItemJson, statusCode: 201);
        }
        return _jsonResponse([_sampleItemJson]);
      });

      final notifier = WishlistNotifier(dio);
      notifier.setGroupId(1);

      final result = await notifier.createWishlistItem(
        groupId: 1,
        title: '掃除機',
      );

      expect(result, true);
      expect(notifier.state.errorMessage, isNull);
    });

    test('createWishlistItem 失敗時に false が返り errorMessage がセットされる', () async {
      final dio = _makeDio((_) async {
        throw DioException(
          requestOptions: RequestOptions(path: '/wishlist'),
          response: Response(
            requestOptions: RequestOptions(path: '/wishlist'),
            statusCode: 400,
            data: {'message': '不正なリクエスト'},
          ),
          type: DioExceptionType.badResponse,
        );
      });

      final notifier = WishlistNotifier(dio);
      notifier.setGroupId(1);

      final result = await notifier.createWishlistItem(
        groupId: 1,
        title: '',
      );

      expect(result, false);
      expect(notifier.state.errorMessage, isNotNull);
      expect(notifier.state.isSubmitting, false);
    });

    test('deleteWishlistItem 成功後に items から該当アイテムが除去される', () async {
      final dio = _makeDio((options) async {
        if (options.method == 'DELETE') {
          return ResponseBody.fromString('', 204);
        }
        return _jsonResponse([_sampleItemJson]);
      });

      final notifier = WishlistNotifier(dio);
      notifier.setGroupId(1);
      await notifier.loadWishlistItems(); // items を先にロード
      expect(notifier.state.items.length, 1);

      final result = await notifier.deleteWishlistItem(1);

      expect(result, true);
      expect(notifier.state.items.where((i) => i.id == 1), isEmpty);
    });
  });
}
