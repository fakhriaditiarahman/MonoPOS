import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Flutter POS'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @home_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Products...'**
  String get home_searchHint;

  /// No description provided for @home_syncronizing.
  ///
  /// In en, this message translates to:
  /// **'Syncronizing'**
  String get home_syncronizing;

  /// No description provided for @home_synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get home_synced;

  /// No description provided for @home_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get home_pending;

  /// No description provided for @home_onlineMode.
  ///
  /// In en, this message translates to:
  /// **'Online mode'**
  String get home_onlineMode;

  /// No description provided for @home_noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection, running in offline mode'**
  String get home_noInternet;

  /// No description provided for @home_enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter Amount'**
  String get home_enterAmount;

  /// No description provided for @home_addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add To Cart'**
  String get home_addToCart;

  /// No description provided for @home_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get home_cancel;

  /// No description provided for @home_noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products available, add product to continue'**
  String get home_noProducts;

  /// No description provided for @home_addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get home_addProduct;

  /// No description provided for @home_transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get home_transaction;

  /// No description provided for @home_pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get home_pay;

  /// No description provided for @home_retail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get home_retail;

  /// No description provided for @home_grosir.
  ///
  /// In en, this message translates to:
  /// **'Grosir'**
  String get home_grosir;

  /// No description provided for @cart_products.
  ///
  /// In en, this message translates to:
  /// **'{count} Products'**
  String cart_products(Object count);

  /// No description provided for @cart_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get cart_confirm;

  /// No description provided for @cart_removeAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure want to remove all product?'**
  String get cart_removeAllConfirm;

  /// No description provided for @cart_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get cart_remove;

  /// No description provided for @cart_removeAll.
  ///
  /// In en, this message translates to:
  /// **'Remove All'**
  String get cart_removeAll;

  /// No description provided for @cart_empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get cart_empty;

  /// No description provided for @cart_noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products added to cart'**
  String get cart_noProducts;

  /// No description provided for @cart_total.
  ///
  /// In en, this message translates to:
  /// **'Total ({count})'**
  String cart_total(Object count);

  /// No description provided for @cart_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get cart_back;

  /// No description provided for @cart_receivedAmount.
  ///
  /// In en, this message translates to:
  /// **'Received Amount'**
  String get cart_receivedAmount;

  /// No description provided for @cart_receivedAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Received amount...'**
  String get cart_receivedAmountHint;

  /// No description provided for @cart_paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get cart_paymentMethod;

  /// No description provided for @cart_bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get cart_bank;

  /// No description provided for @cart_cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cart_cash;

  /// No description provided for @cart_customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name (Optional)'**
  String get cart_customerName;

  /// No description provided for @cart_customerNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Jhone Doe'**
  String get cart_customerNameHint;

  /// No description provided for @cart_description.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get cart_description;

  /// No description provided for @cart_descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description...'**
  String get cart_descriptionHint;

  /// No description provided for @cart_stock.
  ///
  /// In en, this message translates to:
  /// **'Stock: {count}'**
  String cart_stock(Object count);

  /// No description provided for @cart_removeProductConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure want to remove this product?'**
  String get cart_removeProductConfirm;

  /// No description provided for @product_stockSold.
  ///
  /// In en, this message translates to:
  /// **'Stock {stock} | Sold {sold}'**
  String product_stockSold(Object stock, Object sold);

  /// No description provided for @product_retailPrice.
  ///
  /// In en, this message translates to:
  /// **'Retail: {price}'**
  String product_retailPrice(Object price);

  /// No description provided for @product_grosirPrice.
  ///
  /// In en, this message translates to:
  /// **'Grosir: {price}'**
  String product_grosirPrice(Object price);

  /// No description provided for @product_outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get product_outOfStock;

  /// No description provided for @product_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Products...'**
  String get product_searchHint;

  /// No description provided for @product_noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products available, add product to continue'**
  String get product_noProducts;

  /// No description provided for @product_createTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Product'**
  String get product_createTitle;

  /// No description provided for @product_editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get product_editTitle;

  /// No description provided for @product_image.
  ///
  /// In en, this message translates to:
  /// **'Product Image'**
  String get product_image;

  /// No description provided for @product_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get product_nameLabel;

  /// No description provided for @product_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Product name...'**
  String get product_nameHint;

  /// No description provided for @product_retailPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Retail Price'**
  String get product_retailPriceLabel;

  /// No description provided for @product_retailPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Retail price...'**
  String get product_retailPriceHint;

  /// No description provided for @product_wholesalePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Wholesale Price (Optional)'**
  String get product_wholesalePriceLabel;

  /// No description provided for @product_wholesalePriceHint.
  ///
  /// In en, this message translates to:
  /// **'Wholesale price...'**
  String get product_wholesalePriceHint;

  /// No description provided for @product_stockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get product_stockLabel;

  /// No description provided for @product_stockHint.
  ///
  /// In en, this message translates to:
  /// **'Product stock...'**
  String get product_stockHint;

  /// No description provided for @product_barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get product_barcodeLabel;

  /// No description provided for @product_barcodeHint.
  ///
  /// In en, this message translates to:
  /// **'Scan or type barcode...'**
  String get product_barcodeHint;

  /// No description provided for @product_barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get product_barcode;

  /// No description provided for @product_unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get product_unitLabel;

  /// No description provided for @product_descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get product_descriptionLabel;

  /// No description provided for @product_descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Product description...'**
  String get product_descriptionHint;

  /// No description provided for @product_addButton.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get product_addButton;

  /// No description provided for @product_updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Product'**
  String get product_updateButton;

  /// No description provided for @product_deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get product_deleteButton;

  /// No description provided for @product_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure want to delete this product?'**
  String get product_deleteConfirm;

  /// No description provided for @product_deleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted'**
  String get product_deleted;

  /// No description provided for @product_created.
  ///
  /// In en, this message translates to:
  /// **'Product created'**
  String get product_created;

  /// No description provided for @product_updated.
  ///
  /// In en, this message translates to:
  /// **'Product updated'**
  String get product_updated;

  /// No description provided for @product_detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Detail'**
  String get product_detailTitle;

  /// No description provided for @product_editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get product_editProduct;

  /// No description provided for @product_noName.
  ///
  /// In en, this message translates to:
  /// **'(No name)'**
  String get product_noName;

  /// No description provided for @product_addedAt.
  ///
  /// In en, this message translates to:
  /// **'Added at {date}'**
  String product_addedAt(Object date);

  /// No description provided for @product_lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated at {date}'**
  String product_lastUpdated(Object date);

  /// No description provided for @product_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get product_price;

  /// No description provided for @product_stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get product_stock;

  /// No description provided for @product_sold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get product_sold;

  /// No description provided for @product_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get product_description;

  /// No description provided for @product_noDescription.
  ///
  /// In en, this message translates to:
  /// **'(No description)'**
  String get product_noDescription;

  /// No description provided for @product_notFound.
  ///
  /// In en, this message translates to:
  /// **'Not Found'**
  String get product_notFound;

  /// No description provided for @transaction_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Transaction ID...'**
  String get transaction_searchHint;

  /// No description provided for @transaction_noTransaction.
  ///
  /// In en, this message translates to:
  /// **'No transaction available'**
  String get transaction_noTransaction;

  /// No description provided for @transaction_detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction Detail'**
  String get transaction_detailTitle;

  /// No description provided for @transaction_reprint.
  ///
  /// In en, this message translates to:
  /// **'Reprint'**
  String get transaction_reprint;

  /// No description provided for @transaction_created.
  ///
  /// In en, this message translates to:
  /// **'Transaction Created'**
  String get transaction_created;

  /// No description provided for @transaction_id.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transaction_id;

  /// No description provided for @transaction_paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get transaction_paymentMethod;

  /// No description provided for @transaction_createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created By'**
  String get transaction_createdBy;

  /// No description provided for @transaction_createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get transaction_createdAt;

  /// No description provided for @transaction_customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get transaction_customerName;

  /// No description provided for @transaction_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get transaction_description;

  /// No description provided for @transaction_orderedProducts.
  ///
  /// In en, this message translates to:
  /// **'Ordered Products'**
  String get transaction_orderedProducts;

  /// No description provided for @transaction_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get transaction_total;

  /// No description provided for @transaction_paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get transaction_paymentReceived;

  /// No description provided for @transaction_change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get transaction_change;

  /// No description provided for @transaction_notFound.
  ///
  /// In en, this message translates to:
  /// **'Not Found'**
  String get transaction_notFound;

  /// No description provided for @transaction_products.
  ///
  /// In en, this message translates to:
  /// **'{count} Products'**
  String transaction_products(Object count);

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settings_profile;

  /// No description provided for @settings_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_theme;

  /// No description provided for @settings_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settings_close;

  /// No description provided for @settings_darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settings_darkMode;

  /// No description provided for @settings_printerSettings.
  ///
  /// In en, this message translates to:
  /// **'Printer Settings'**
  String get settings_printerSettings;

  /// No description provided for @settings_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_about;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settings_english;

  /// No description provided for @settings_indonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get settings_indonesian;

  /// No description provided for @settings_noName.
  ///
  /// In en, this message translates to:
  /// **'(No Name)'**
  String get settings_noName;

  /// No description provided for @profile_editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profile_editTitle;

  /// No description provided for @profile_image.
  ///
  /// In en, this message translates to:
  /// **'Profile Image'**
  String get profile_image;

  /// No description provided for @profile_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profile_nameLabel;

  /// No description provided for @profile_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name...'**
  String get profile_nameHint;

  /// No description provided for @profile_emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profile_emailLabel;

  /// No description provided for @profile_emailHint.
  ///
  /// In en, this message translates to:
  /// **'Your email...'**
  String get profile_emailHint;

  /// No description provided for @profile_phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get profile_phoneLabel;

  /// No description provided for @profile_phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Your phone number...'**
  String get profile_phoneHint;

  /// No description provided for @profile_update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get profile_update;

  /// No description provided for @profile_cropPhoto.
  ///
  /// In en, this message translates to:
  /// **'Crop Photo'**
  String get profile_cropPhoto;

  /// No description provided for @profile_updated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profile_updated;

  /// No description provided for @printer_title.
  ///
  /// In en, this message translates to:
  /// **'Printer Settings'**
  String get printer_title;

  /// No description provided for @printer_paperSize.
  ///
  /// In en, this message translates to:
  /// **'Paper Size'**
  String get printer_paperSize;

  /// No description provided for @printer_connectionTypes.
  ///
  /// In en, this message translates to:
  /// **'Connection Types'**
  String get printer_connectionTypes;

  /// No description provided for @printer_selectConnection.
  ///
  /// In en, this message translates to:
  /// **'Select connection types'**
  String get printer_selectConnection;

  /// No description provided for @printer_usb.
  ///
  /// In en, this message translates to:
  /// **'USB'**
  String get printer_usb;

  /// No description provided for @printer_bluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get printer_bluetooth;

  /// No description provided for @printer_ble.
  ///
  /// In en, this message translates to:
  /// **'BLE'**
  String get printer_ble;

  /// No description provided for @printer_network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get printer_network;

  /// No description provided for @printer_allConnections.
  ///
  /// In en, this message translates to:
  /// **'All connection types'**
  String get printer_allConnections;

  /// No description provided for @printer_availableDevices.
  ///
  /// In en, this message translates to:
  /// **'Available Devices'**
  String get printer_availableDevices;

  /// No description provided for @printer_scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning for printers...'**
  String get printer_scanning;

  /// No description provided for @printer_noDevice.
  ///
  /// In en, this message translates to:
  /// **'(No printer detected)'**
  String get printer_noDevice;

  /// No description provided for @about_title.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about_title;

  /// No description provided for @about_appName.
  ///
  /// In en, this message translates to:
  /// **'Flutter POS'**
  String get about_appName;

  /// No description provided for @about_version.
  ///
  /// In en, this message translates to:
  /// **'version {version}'**
  String about_version(Object version);

  /// No description provided for @about_description.
  ///
  /// In en, this message translates to:
  /// **'A Point of Sale (POS) application built with Flutter framework. This application manages product data, transactions, and user data. The data is stored locally using SQLite database and can be synchronized with REST API server.'**
  String get about_description;

  /// No description provided for @about_learningResource.
  ///
  /// In en, this message translates to:
  /// **'This project serves as a learning resource for Flutter developers who want to learn about Clean Architecture, Riverpod state management, GoRouter navigation, and SQLite database integration. The project is open source and available on GitHub.'**
  String get about_learningResource;

  /// No description provided for @about_developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed with ❤️ by'**
  String get about_developedBy;

  /// No description provided for @about_developerName.
  ///
  /// In en, this message translates to:
  /// **'Fakhri Aditia Rahman'**
  String get about_developerName;

  /// No description provided for @about_github.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get about_github;

  /// No description provided for @about_website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get about_website;

  /// No description provided for @error_backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get error_backToHome;

  /// No description provided for @shared_oops.
  ///
  /// In en, this message translates to:
  /// **'Oops!'**
  String get shared_oops;

  /// No description provided for @shared_somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, please contact developer.'**
  String get shared_somethingWrong;

  /// No description provided for @shared_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get shared_close;

  /// No description provided for @shared_nothingToShow.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show'**
  String get shared_nothingToShow;

  /// No description provided for @shared_somethingWrongRetry.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.\nPlease try again later.'**
  String get shared_somethingWrongRetry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
