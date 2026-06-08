import 'dart:io';

import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mono_pos/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/themes/app_sizes.dart';
import '../../providers/products/product_form_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_drop_down.dart';
import '../../widgets/app_icon_button.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';
import '../home/components/barcode_scanner_screen.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final int? id;

  const ProductFormScreen({
    super.key,
    this.id,
  });

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final wholesalePriceController = TextEditingController();
  final stockController = TextEditingController();
  final barcodeController = TextEditingController();
  final descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(productFormNotifierProvider.notifier).initProductForm(widget.id);

      final state = ref.read(productFormNotifierProvider);
      nameController.text = state.name ?? '';
      priceController.text = state.price?.toString() ?? '';
      wholesalePriceController.text = state.wholesalePrice?.toString() ?? '';
      stockController.text = state.stock?.toString() ?? '';
      barcodeController.text = state.barcode ?? '';
      descController.text = state.description ?? '';
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    wholesalePriceController.dispose();
    stockController.dispose();
    barcodeController.dispose();
    descController.dispose();
    super.dispose();
  }

  void onTapImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile == null) return;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Crop Photo'),
        IOSUiSettings(title: 'Crop Photo'),
      ],
    );

    if (croppedFile != null) {
      var file = File(croppedFile.path);
      ref.read(productFormNotifierProvider.notifier).onChangedImage(file);
    }
  }

  void createProduct() async {
    var res = await AppDialog.showProgress(() {
      return ref.read(productFormNotifierProvider.notifier).createProduct();
    });

    if (res.isSuccess) {
      if (!mounted) return;
      context.go('/products');
      AppSnackBar.show(AppLocalizations.of(context)!.product_created);
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  void updatedProduct() async {
    var res = await AppDialog.showProgress(() {
      return ref.read(productFormNotifierProvider.notifier).updatedProduct(widget.id!);
    });

    if (res.isSuccess) {
      if (!mounted) return;
      context.pop();
      AppSnackBar.show(AppLocalizations.of(context)!.product_updated);
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  void deleteProduct() async {
    var res = await AppDialog.showProgress(() {
      return ref.read(productFormNotifierProvider.notifier).deleteProduct(widget.id!);
    });

    if (res.isSuccess) {
      if (!mounted) return;
      context.go('/products');
      AppSnackBar.show(AppLocalizations.of(context)!.product_deleted);
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(productFormNotifierProvider.notifier);

    final isLoaded = ref.watch(productFormNotifierProvider.select((s) => s.isLoaded));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.id == null
              ? AppLocalizations.of(context)!.product_createTitle
              : AppLocalizations.of(context)!.product_editTitle,
        ),
        titleSpacing: 0,
      ),
      body: !isLoaded
          ? const AppProgressIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ImageSection(onTapImage: onTapImage),
                  _NameField(
                    controller: nameController,
                    onChanged: notifier.onChangedName,
                  ),
                  _RetailPriceField(
                    controller: priceController,
                    onChanged: notifier.onChangedPrice,
                  ),
                  _WholesalePriceField(
                    controller: wholesalePriceController,
                    onChanged: notifier.onChangedWholesalePrice,
                  ),
                  _StockField(
                    controller: stockController,
                    onChanged: notifier.onChangedStock,
                  ),
                  _BarcodeField(
                    controller: barcodeController,
                    onChanged: notifier.onChangedBarcode,
                  ),
                  _UnitField(
                    onChanged: notifier.onChangedUnit,
                  ),
                  _DescriptionField(
                    controller: descController,
                    onChanged: notifier.onChangedDesc,
                  ),
                  _CreateOrUpdateButton(
                    id: widget.id,
                    onCreateProduct: createProduct,
                    onUpdatedProduct: updatedProduct,
                  ),
                  _DeleteButton(
                    id: widget.id,
                    onDeleteProduct: deleteProduct,
                  ),
                ],
              ),
            ),
    );
  }
}

class _ImageSection extends ConsumerWidget {
  final VoidCallback onTapImage;

  const _ImageSection({required this.onTapImage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageFile = ref.watch(productFormNotifierProvider.select((p) => p.imageFile));
    final imageUrl = ref.watch(productFormNotifierProvider.select((p) => p.imageUrl));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.product_image,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.padding / 2),
        Stack(
          children: [
            GestureDetector(
              onTap: onTapImage,
              child: AppImage(
                image: imageFile?.path ?? imageUrl ?? '',
                imgProvider: imageFile != null ? ImgProvider.fileImage : ImgProvider.networkImage,
                width: 100,
                height: 100,
                borderRadius: BorderRadius.circular(AppSizes.radius),
                backgroundColor: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  width: 1,
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                errorWidget: Icon(
                  Icons.image,
                  color: Theme.of(context).colorScheme.surfaceDim,
                  size: 32,
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: AppIconButton(
                icon: Icons.camera_alt_rounded,
                iconSize: 14,
                borderRadius: 8,
                padding: const EdgeInsets.all(6),
                onTap: onTapImage,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _NameField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppTextField(
        controller: controller,
        labelText: AppLocalizations.of(context)!.product_nameLabel,
        hintText: AppLocalizations.of(context)!.product_nameHint,
        onChanged: onChanged,
      ),
    );
  }
}

class _BarcodeField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _BarcodeField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: controller,
              labelText: AppLocalizations.of(context)!.product_barcodeLabel,
              hintText: AppLocalizations.of(context)!.product_barcodeHint,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSizes.radius),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSizes.radius),
                onTap: () async {
                  final result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BarcodeScannerScreen(),
                    ),
                  );
                  if (result != null) {
                    controller.text = result;
                    onChanged(result);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetailPriceField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _RetailPriceField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppTextField(
        controller: controller,
        labelText: AppLocalizations.of(context)!.product_retailPriceLabel,
        hintText: AppLocalizations.of(context)!.product_retailPriceHint,
        type: AppTextFieldType.currency,
        onChanged: onChanged,
      ),
    );
  }
}

class _WholesalePriceField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _WholesalePriceField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppTextField(
        controller: controller,
        labelText: AppLocalizations.of(context)!.product_wholesalePriceLabel,
        hintText: AppLocalizations.of(context)!.product_wholesalePriceHint,
        type: AppTextFieldType.currency,
        onChanged: onChanged,
      ),
    );
  }
}

class _StockField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _StockField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppTextField(
        controller: controller,
        labelText: AppLocalizations.of(context)!.product_stockLabel,
        hintText: AppLocalizations.of(context)!.product_stockHint,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
      ),
    );
  }
}

class _UnitField extends ConsumerWidget {
  final ValueChanged<String> onChanged;

  const _UnitField({
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUnit = ref.watch(productFormNotifierProvider.select((s) => s.unit));

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppDropDown(
        labelText: AppLocalizations.of(context)!.product_unitLabel,
        selectedValue: selectedUnit,
        dropdownItems: const [
          DropdownMenuItem(value: 'pcs', child: Text('pcs')),
          DropdownMenuItem(value: 'dus', child: Text('dus')),
          DropdownMenuItem(value: 'kg', child: Text('kg')),
          DropdownMenuItem(value: 'pack', child: Text('pack')),
          DropdownMenuItem(value: 'box', child: Text('box')),
          DropdownMenuItem(value: 'sachet', child: Text('sachet')),
          DropdownMenuItem(value: 'botol', child: Text('botol')),
          DropdownMenuItem(value: 'lusin', child: Text('lusin')),
          DropdownMenuItem(value: 'kodi', child: Text('kodi')),
          DropdownMenuItem(value: 'rim', child: Text('rim')),
          DropdownMenuItem(value: 'bungkus', child: Text('bungkus')),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _DescriptionField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppTextField(
        controller: controller,
        labelText: AppLocalizations.of(context)!.product_descriptionLabel,
        hintText: AppLocalizations.of(context)!.product_descriptionHint,
        maxLines: 4,
        onChanged: onChanged,
      ),
    );
  }
}

class _CreateOrUpdateButton extends ConsumerWidget {
  final int? id;
  final VoidCallback onCreateProduct;
  final VoidCallback onUpdatedProduct;

  const _CreateOrUpdateButton({
    required this.id,
    required this.onCreateProduct,
    required this.onUpdatedProduct,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFormValid = ref.watch(
      productFormNotifierProvider.select((s) {
        return (s.name?.isNotEmpty ?? false) && (s.price ?? 0) > 0 && (s.stock ?? 0) > 0;
      }),
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding * 1.5),
      child: AppButton(
        text: id == null
            ? AppLocalizations.of(context)!.product_addButton
            : AppLocalizations.of(context)!.product_updateButton,
        enabled: isFormValid,
        onTap: () {
          if (id != null) {
            onUpdatedProduct();
          } else {
            onCreateProduct();
          }
        },
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final int? id;
  final VoidCallback onDeleteProduct;

  const _DeleteButton({
    required this.id,
    required this.onDeleteProduct,
  });

  @override
  Widget build(BuildContext context) {
    if (id == null) return const SizedBox(height: AppSizes.padding * 2);

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSizes.padding,
        bottom: AppSizes.padding * 2,
      ),
      child: AppButton(
        text: AppLocalizations.of(context)!.product_deleteButton,
        textColor: Theme.of(context).colorScheme.error,
        buttonColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        onTap: () {
          AppDialog.show(
            title: AppLocalizations.of(context)!.cart_confirm,
            text: AppLocalizations.of(context)!.product_deleteConfirm,
            leftButtonText: AppLocalizations.of(context)!.home_cancel,
            rightButtonText: AppLocalizations.of(context)!.cart_remove,
            rightButtonColor: Theme.of(context).colorScheme.errorContainer,
            rightButtonTextColor: Theme.of(context).colorScheme.error,
            onTapRightButton: (context) async {
              context.pop();
              onDeleteProduct();
            },
          );
        },
      ),
    );
  }
}
