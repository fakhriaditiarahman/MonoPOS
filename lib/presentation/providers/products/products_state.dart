import '../../../domain/entities/product_entity.dart';

class ProductsState {
  final List<ProductEntity>? allProducts;
  final bool isLoadingMore;
  final String? contains;

  const ProductsState({this.allProducts, this.isLoadingMore = false, this.contains});

  ProductsState copyWith({
    List<ProductEntity>? allProducts,
    bool? isLoadingMore,
    String? contains,
  }) {
    return ProductsState(
      allProducts: allProducts ?? this.allProducts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      contains: contains ?? this.contains,
    );
  }
}
