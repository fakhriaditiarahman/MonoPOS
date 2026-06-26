import '../../../domain/entities/ordered_product_entity.dart';

class HomeState {
  final List<OrderedProductEntity> orderedProducts;
  final int receivedAmount;
  final String selectedPaymentMethod;
  final String selectedPaymentType;
  final String? customerName;
  final String? customerId;
  final String? dueDate;
  final String? description;
  final bool isPanelExpanded;
  final String selectedPriceType;

  const HomeState({
    this.orderedProducts = const [],
    this.receivedAmount = 0,
    this.selectedPaymentMethod = 'cash',
    this.selectedPaymentType = 'cash',
    this.customerName,
    this.customerId,
    this.dueDate,
    this.description,
    this.isPanelExpanded = false,
    this.selectedPriceType = 'retail',
  });

  HomeState copyWith({
    List<OrderedProductEntity>? orderedProducts,
    int? receivedAmount,
    String? selectedPaymentMethod,
    String? selectedPaymentType,
    String? customerName,
    String? customerId,
    String? dueDate,
    String? description,
    bool? isPanelExpanded,
    String? selectedPriceType,
  }) {
    return HomeState(
      orderedProducts: orderedProducts ?? this.orderedProducts,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      selectedPaymentType: selectedPaymentType ?? this.selectedPaymentType,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      isPanelExpanded: isPanelExpanded ?? this.isPanelExpanded,
      selectedPriceType: selectedPriceType ?? this.selectedPriceType,
    );
  }
}
