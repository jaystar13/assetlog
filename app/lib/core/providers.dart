import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/asset_service.dart';
import '../services/deep_link_service.dart';
import '../services/quote_service.dart';
import '../services/share_group_service.dart';
import '../services/transaction_service.dart';
import 'auth/auth_notifier.dart';
import 'auth/auth_state.dart';
import 'network/api_client.dart';
import 'storage/token_storage.dart';

// ─── Infrastructure ───────────────────────────────────

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(),
);

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return createApiClient(tokenStorage);
});

// ─── Services ─────────────────────────────────────────

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(dioProvider)),
);

final transactionServiceProvider = Provider<TransactionService>(
  (ref) => TransactionService(ref.watch(dioProvider)),
);

final assetServiceProvider = Provider<AssetService>(
  (ref) => AssetService(ref.watch(dioProvider)),
);

final shareGroupServiceProvider = Provider<ShareGroupService>(
  (ref) => ShareGroupService(ref.watch(dioProvider)),
);

final quoteServiceProvider = Provider<QuoteService>(
  (ref) => QuoteService(ref.watch(dioProvider)),
);

final deepLinkServiceProvider = Provider<DeepLinkService>(
  (ref) => DeepLinkService(),
);

// ─── Auth State ───────────────────────────────────────

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
