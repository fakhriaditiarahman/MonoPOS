import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../../core/themes/app_sizes.dart';
import '../../../domain/entities/product_entity.dart';
import '../../providers/home/home_notifier.dart';
import '../../providers/main/main_notifier.dart';
import '../../providers/products/products_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_loading_more_indicator.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';
import '../products/components/products_card.dart';
import 'components/barcode_scanner_screen.dart';
import 'components/cart_panel_body.dart';
import 'components/cart_panel_footer.dart';
import 'components/cart_panel_header.dart';
import 'components/order_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final scrollController = ScrollController();
  final searchFieldController = TextEditingController();
  final panelController = PanelController();

  @override
  void initState() {
    scrollController.addListener(scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) => onRefresh());
    super.initState();
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    searchFieldController.dispose();
    super.dispose();
  }

  void scrollListener() async {
    final productsState = ref.read(productsNotifierProvider);

    // Automatically load more data on end of scroll position
    if (scrollController.offset == scrollController.position.maxScrollExtent) {
      await ref
          .read(productsNotifierProvider.notifier)
          .getAllProducts(
            offset: productsState.allProducts?.length,
          );
    }
  }

  Future<void> onRefresh() async {
    await ref.read(productsNotifierProvider.notifier).getAllProducts();
  }

  @override
  Widget build(BuildContext context) {
    final homeNotifier = ref.read(homeNotifierProvider.notifier);

    return Scaffold(
      body: SlidingUpPanel(
        controller: panelController,
        minHeight: 88,
        maxHeight: AppSizes.screenHeight(context) - AppSizes.appBarHeight() - AppSizes.viewPadding(context).top,
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSizes.radius * 2),
          topRight: Radius.circular(AppSizes.radius * 2),
        ),
        body: _Body(
          scrollController: scrollController,
          searchFieldController: searchFieldController,
          onRefresh: onRefresh,
        ),
        header: CartPanelHeader(panelController: panelController),
        panel: CartPanelBody(panelController: panelController),
        footer: CartPanelFooter(panelController: panelController),
        onPanelOpened: () => homeNotifier.onChangedIsPanelExpanded(true),
        onPanelClosed: () => homeNotifier.onChangedIsPanelExpanded(false),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final ScrollController scrollController;
  final TextEditingController searchFieldController;
  final Future<void> Function() onRefresh;

  const _Body({
    required this.scrollController,
    required this.searchFieldController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProducts = ref.watch(productsNotifierProvider.select((p) => p.allProducts));
    final isLoadingMore = ref.watch(productsNotifierProvider.select((p) => p.isLoadingMore));

    return Scaffold(
      appBar: AppBar(
        title: const _Title(),
        elevation: 0,
        shadowColor: Colors.transparent,
        actions: const [
          _ScanButton(),
          _SyncButton(),
          _NetworkInfo(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: Scrollbar(
          child: CustomScrollView(
            controller: scrollController,
            // Disable scroll when data is null or empty
            physics: (allProducts?.isEmpty ?? true) ? const NeverScrollableScrollPhysics() : null,
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                automaticallyImplyLeading: false,
                collapsedHeight: 110,
                titleSpacing: 0,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
                  child: Column(
                    children: [
                      _SearchField(controller: searchFieldController),
                      const SizedBox(height: 6),
                      const _PriceTypeToggle(),
                    ],
                  ),
                ),
              ),
              SliverLayoutBuilder(
                builder: (context, constraint) {
                  if (allProducts == null) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      fillOverscroll: true,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 140),
                        child: AppProgressIndicator(),
                      ),
                    );
                  }

                  if (allProducts.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      fillOverscroll: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 140),
                        child: AppEmptyState(
                          subtitle: 'No products available, add product to continue',
                          buttonText: 'Add Product',
                          onTapButton: () => context.push('/products/product-create'),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSizes.padding, 2, AppSizes.padding, AppSizes.padding),
                    sliver: SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 1 / 1.5,
                        crossAxisSpacing: AppSizes.padding / 2,
                        mainAxisSpacing: AppSizes.padding / 2,
                      ),
                      itemCount: allProducts.length,
                      itemBuilder: (context, i) {
                        return _ProductCard(product: allProducts[i]);
                      },
                    ),
                  );
                },
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 140),
                sliver: SliverToBoxAdapter(
                  child: AppLoadingMoreIndicator(isLoading: isLoadingMore),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Title extends ConsumerWidget {
  const _Title();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(mainNotifierProvider.select((p) => p.user));

    return Row(
      children: [
        AppImage(
          image: user?.imageUrl ?? '',
          borderRadius: BorderRadius.circular(100),
          width: 30,
          height: 30,
          backgroundColor: Theme.of(context).colorScheme.surface,
          errorWidget: Icon(
            Icons.person,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.name ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                height: 0,
              ),
            ),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 0),
      child: AppButton(
        height: 26,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding / 2),
        buttonColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
        child: Icon(
          Icons.qr_code_scanner_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BarcodeScannerScreen(),
            ),
          );
        },
      ),
    );
  }
}

class _SyncButton extends ConsumerWidget {
  const _SyncButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHasQueuedActions = ref.watch(mainNotifierProvider.select((p) => p.isHasQueuedActions));
    final isSyncronizing = ref.watch(mainNotifierProvider.select((p) => p.isSyncronizing));

    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.padding / 4),
      child: AppButton(
        height: 26,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding / 2),
        buttonColor: isHasQueuedActions && !isSyncronizing
            ? Theme.of(context).colorScheme.surfaceContainer
            : Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
        child: Row(
          children: [
            Icon(
              isSyncronizing
                  ? Icons.sync
                  : isHasQueuedActions
                  ? Icons.cloud_done_sharp
                  : Icons.sync_problem_sharp,
              size: 12,
              color: isHasQueuedActions && !isSyncronizing
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: AppSizes.padding / 4),
            Text(
              isSyncronizing
                  ? 'Syncronizing'
                  : isHasQueuedActions
                  ? 'Synced'
                  : 'Pending',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isHasQueuedActions && !isSyncronizing
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        onTap: () {
          ref.read(mainNotifierProvider.notifier).getUserData();
        },
      ),
    );
  }
}

class _NetworkInfo extends ConsumerWidget {
  const _NetworkInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHasInternet = ref.watch(mainNotifierProvider.select((provider) => provider.isHasInternet));

    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.padding),
      child: AppButton(
        height: 26,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding / 2),
        buttonColor: isHasInternet
            ? Theme.of(context).colorScheme.surfaceContainer
            : Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
        child: Icon(
          isHasInternet ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          size: 12,
          color: isHasInternet ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
        ),
        onTap: () {
          AppSnackBar.show(isHasInternet ? 'Online mode' : 'No internet connection, running in offline mode');
        },
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppTextField(
      controller: controller,
      hintText: 'Search Products...',
      type: AppTextFieldType.search,
      textInputAction: TextInputAction.search,
      onEditingComplete: () {
        FocusScope.of(context).unfocus();
        ref.read(productsNotifierProvider.notifier).resetProducts();
        ref.read(productsNotifierProvider.notifier).getAllProducts(contains: controller.text);
      },
      onTapClearButton: () {
        ref.read(productsNotifierProvider.notifier).getAllProducts(contains: controller.text);
      },
    );
  }
}

class _PriceTypeToggle extends ConsumerWidget {
  const _PriceTypeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPriceType = ref.watch(homeNotifierProvider.select((s) => s.selectedPriceType));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => ref.read(homeNotifierProvider.notifier).onChangedPriceType('retail'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selectedPriceType == 'retail' ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Retail',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: selectedPriceType == 'retail'
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => ref.read(homeNotifierProvider.notifier).onChangedPriceType('grosir'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selectedPriceType == 'grosir' ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Grosir',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: selectedPriceType == 'grosir'
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.outline,
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

class _ProductCard extends ConsumerWidget {
  final ProductEntity product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);
    bool isGrosir = homeState.selectedPriceType == 'grosir';
    int displayPrice = isGrosir && product.wholesalePrice != null ? product.wholesalePrice! : product.price;
    bool hasWholesalePrice = product.wholesalePrice != null;

    return ProductsCard(
      product: product,
      enabled: product.stock > 0 && (!isGrosir || hasWholesalePrice),
      onTap: () {
        int currentQty = homeState.orderedProducts.where((e) => e.productId == product.id).firstOrNull?.quantity ?? 0;

        AppDialog.show(
          title: 'Enter Amount',
          child: OrderCard(
            name: product.name,
            imageUrl: product.imageUrl,
            stock: product.stock,
            price: displayPrice,
            priceType: homeState.selectedPriceType,
            unit: product.unit,
            initialQuantity: currentQty,
            onChangedQuantity: (val) {
              currentQty = val;
            },
          ),
          rightButtonText: 'Add To Cart',
          leftButtonText: 'Cancel',
          onTapLeftButton: (context) {
            context.pop();
          },
          onTapRightButton: (context) {
            ref.read(homeNotifierProvider.notifier).onAddOrderedProduct(product, currentQty == 0 ? 1 : currentQty);
            context.pop();
          },
        );
      },
    );
  }
}
