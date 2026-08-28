import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/usecases/params/base_params.dart';
import '../../../domain/usecases/product_usecases.dart';
import '../auth/auth_notifier.dart';
import 'products_state.dart';

final productsNotifierProvider = NotifierProvider<ProductsNotifier, ProductsState>(
  ProductsNotifier.new,
);

final berandaProductsNotifierProvider = NotifierProvider<ProductsNotifier, ProductsState>(
  ProductsNotifier.new,
);

class ProductsNotifier extends Notifier<ProductsState> {
  @override
  ProductsState build() {
    return const ProductsState();
  }

  String _requireUserId() {
    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated) return authState.user!.id;
    throw 'Unauthenticated!';
  }

  void resetProducts() {
    state = const ProductsState();
  }

  Future<void> getAllProducts({int? offset, String? contains}) async {
    final userId = _requireUserId();

    if (offset != null) {
      if (state.isLoadingMore) return;
      state = state.copyWith(isLoadingMore: true);
    }

    var params = BaseParams(
      param: userId,
      offset: offset,
      contains: offset == null ? contains : state.contains,
    );

    final productRepository = ref.read(productRepositoryProvider);
    var res = await GetUserProductsUsecase(productRepository).call(params);

    if (res.isSuccess) {
      if (offset == null) {
        state = state.copyWith(allProducts: res.data ?? [], contains: contains, isLoadingMore: false);
      } else {
        final current = state.allProducts ?? [];
        final incoming = res.data ?? [];
        final merged = <ProductEntity>[];
        final seen = <String>{};
        for (final p in [...current, ...incoming]) {
          final id = p.id?.toString() ?? '';
          if (id.isNotEmpty && !seen.add(id)) continue;
          merged.add(p);
        }
        state = state.copyWith(allProducts: merged, isLoadingMore: false, contains: state.contains);
      }
    } else {
      state = state.copyWith(isLoadingMore: false);
      throw Exception(res.error?.toString() ?? 'Failed to load data');
    }
  }
}
