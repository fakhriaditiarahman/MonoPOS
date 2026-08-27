import 'package:equatable/equatable.dart';

class ProductDataState extends Equatable {
  final bool isBusy;
  final int? exportedCount;
  final int? importedCount;
  final String? error;

  const ProductDataState({
    this.isBusy = false,
    this.exportedCount,
    this.importedCount,
    this.error,
  });

  ProductDataState copyWith({
    bool? isBusy,
    int? exportedCount,
    int? importedCount,
    String? error,
  }) {
    return ProductDataState(
      isBusy: isBusy ?? this.isBusy,
      exportedCount: exportedCount ?? this.exportedCount,
      importedCount: importedCount ?? this.importedCount,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isBusy, exportedCount, importedCount, error];
}
