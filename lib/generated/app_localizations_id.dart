// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Flutter POS';

  @override
  String get home => 'Beranda';

  @override
  String get products => 'Produk';

  @override
  String get transactions => 'Transaksi';

  @override
  String get settings => 'Pengaturan';

  @override
  String get home_searchHint => 'Cari Produk...';

  @override
  String get home_syncronizing => 'Menyinkronkan';

  @override
  String get home_synced => 'Tersinkron';

  @override
  String get home_pending => 'Menunggu';

  @override
  String get home_onlineMode => 'Mode daring';

  @override
  String get home_noInternet => 'Tidak ada koneksi internet, berjalan dalam mode luring';

  @override
  String get home_enterAmount => 'Masukkan Jumlah';

  @override
  String get home_addToCart => 'Tambah ke Keranjang';

  @override
  String get home_cancel => 'Batal';

  @override
  String get home_noProducts => 'Tidak ada produk, tambah produk untuk melanjutkan';

  @override
  String get home_addProduct => 'Tambah Produk';

  @override
  String get home_transaction => 'Transaksi';

  @override
  String get home_pay => 'Bayar';

  @override
  String get home_retail => 'Eceran';

  @override
  String get home_grosir => 'Grosir';

  @override
  String cart_products(Object count) {
    return '$count Produk';
  }

  @override
  String get cart_confirm => 'Konfirmasi';

  @override
  String get cart_removeAllConfirm => 'Yakin ingin menghapus semua produk?';

  @override
  String get cart_remove => 'Hapus';

  @override
  String get cart_removeAll => 'Hapus Semua';

  @override
  String get cart_empty => 'Kosong';

  @override
  String get cart_noProducts => 'Belum ada produk di keranjang';

  @override
  String cart_total(Object count) {
    return 'Total ($count)';
  }

  @override
  String get cart_back => 'Kembali';

  @override
  String get cart_receivedAmount => 'Jumlah Diterima';

  @override
  String get cart_receivedAmountHint => 'Jumlah yang diterima...';

  @override
  String get cart_paymentMethod => 'Metode Pembayaran';

  @override
  String get cart_bank => 'Bank';

  @override
  String get cart_cash => 'Tunai';

  @override
  String get cart_customerName => 'Nama Pelanggan (Opsional)';

  @override
  String get cart_customerNameHint => 'Misal: Budi Santoso';

  @override
  String get cart_description => 'Deskripsi (Opsional)';

  @override
  String get cart_descriptionHint => 'Deskripsi...';

  @override
  String cart_stock(Object count) {
    return 'Stok: $count';
  }

  @override
  String get cart_removeProductConfirm => 'Yakin ingin menghapus produk ini?';

  @override
  String product_stockSold(Object stock, Object sold) {
    return 'Stok $stock | Terjual $sold';
  }

  @override
  String product_retailPrice(Object price) {
    return 'Eceran: $price';
  }

  @override
  String product_grosirPrice(Object price) {
    return 'Grosir: $price';
  }

  @override
  String get product_outOfStock => 'Stok habis';

  @override
  String get product_searchHint => 'Cari Produk...';

  @override
  String get product_noProducts => 'Tidak ada produk, tambah produk untuk melanjutkan';

  @override
  String get product_createTitle => 'Buat Produk';

  @override
  String get product_editTitle => 'Edit Produk';

  @override
  String get product_image => 'Gambar Produk';

  @override
  String get product_nameLabel => 'Nama';

  @override
  String get product_nameHint => 'Nama produk...';

  @override
  String get product_retailPriceLabel => 'Harga Eceran';

  @override
  String get product_retailPriceHint => 'Harga eceran...';

  @override
  String get product_wholesalePriceLabel => 'Harga Grosir (Opsional)';

  @override
  String get product_wholesalePriceHint => 'Harga grosir...';

  @override
  String get product_stockLabel => 'Stok';

  @override
  String get product_stockHint => 'Stok produk...';

  @override
  String get product_barcodeLabel => 'Barcode';

  @override
  String get product_barcodeHint => 'Scan atau ketik barcode...';

  @override
  String get product_barcode => 'Barcode';

  @override
  String get product_unitLabel => 'Satuan';

  @override
  String get product_descriptionLabel => 'Deskripsi';

  @override
  String get product_descriptionHint => 'Deskripsi produk...';

  @override
  String get product_addButton => 'Tambah Produk';

  @override
  String get product_updateButton => 'Perbarui Produk';

  @override
  String get product_deleteButton => 'Hapus';

  @override
  String get product_deleteConfirm => 'Yakin ingin menghapus produk ini?';

  @override
  String get product_deleted => 'Produk dihapus';

  @override
  String get product_created => 'Produk dibuat';

  @override
  String get product_updated => 'Produk diperbarui';

  @override
  String get product_detailTitle => 'Detail Produk';

  @override
  String get product_editProduct => 'Edit Produk';

  @override
  String get product_noName => '(Tanpa nama)';

  @override
  String product_addedAt(Object date) {
    return 'Ditambahkan pada $date';
  }

  @override
  String product_lastUpdated(Object date) {
    return 'Terakhir diperbarui pada $date';
  }

  @override
  String get product_price => 'Harga';

  @override
  String get product_stock => 'Stok';

  @override
  String get product_sold => 'Terjual';

  @override
  String get product_description => 'Deskripsi';

  @override
  String get product_noDescription => '(Tidak ada deskripsi)';

  @override
  String get product_notFound => 'Tidak Ditemukan';

  @override
  String get transaction_searchHint => 'Cari ID Transaksi...';

  @override
  String get transaction_noTransaction => 'Tidak ada transaksi';

  @override
  String get transaction_detailTitle => 'Detail Transaksi';

  @override
  String get transaction_reprint => 'Cetak Ulang';

  @override
  String get transaction_created => 'Transaksi Dibuat';

  @override
  String get transaction_id => 'ID Transaksi';

  @override
  String get transaction_paymentMethod => 'Metode Pembayaran';

  @override
  String get transaction_createdBy => 'Dibuat Oleh';

  @override
  String get transaction_createdAt => 'Dibuat Pada';

  @override
  String get transaction_customerName => 'Nama Pelanggan';

  @override
  String get transaction_description => 'Deskripsi';

  @override
  String get transaction_orderedProducts => 'Produk Dipesan';

  @override
  String get transaction_total => 'Total';

  @override
  String get transaction_paymentReceived => 'Pembayaran Diterima';

  @override
  String get transaction_change => 'Kembalian';

  @override
  String get transaction_notFound => 'Tidak Ditemukan';

  @override
  String transaction_products(Object count) {
    return '$count Produk';
  }

  @override
  String get settings_title => 'Pengaturan';

  @override
  String get settings_profile => 'Profil';

  @override
  String get settings_theme => 'Tema';

  @override
  String get settings_close => 'Tutup';

  @override
  String get settings_darkMode => 'Mode Gelap';

  @override
  String get settings_printerSettings => 'Pengaturan Printer';

  @override
  String get settings_about => 'Tentang';

  @override
  String get settings_language => 'Bahasa';

  @override
  String get settings_english => 'Inggris';

  @override
  String get settings_indonesian => 'Indonesia';

  @override
  String get settings_noName => '(Tanpa Nama)';

  @override
  String get profile_editTitle => 'Edit Profil';

  @override
  String get profile_image => 'Gambar Profil';

  @override
  String get profile_nameLabel => 'Nama';

  @override
  String get profile_nameHint => 'Nama Anda...';

  @override
  String get profile_emailLabel => 'Email';

  @override
  String get profile_emailHint => 'Email Anda...';

  @override
  String get profile_phoneLabel => 'Nomor Telepon';

  @override
  String get profile_phoneHint => 'Nomor telepon Anda...';

  @override
  String get profile_update => 'Perbarui';

  @override
  String get profile_cropPhoto => 'Pangkas Foto';

  @override
  String get profile_updated => 'Profil diperbarui';

  @override
  String get printer_title => 'Pengaturan Printer';

  @override
  String get printer_paperSize => 'Ukuran Kertas';

  @override
  String get printer_connectionTypes => 'Tipe Koneksi';

  @override
  String get printer_selectConnection => 'Pilih tipe koneksi';

  @override
  String get printer_usb => 'USB';

  @override
  String get printer_bluetooth => 'Bluetooth';

  @override
  String get printer_ble => 'BLE';

  @override
  String get printer_network => 'Jaringan';

  @override
  String get printer_allConnections => 'Semua tipe koneksi';

  @override
  String get printer_availableDevices => 'Perangkat Tersedia';

  @override
  String get printer_scanning => 'Memindai printer...';

  @override
  String get printer_noDevice => '(Tidak ada printer terdeteksi)';

  @override
  String get about_title => 'Tentang';

  @override
  String get about_appName => 'Flutter POS';

  @override
  String about_version(Object version) {
    return 'versi $version';
  }

  @override
  String get about_description =>
      'Aplikasi Point of Sale (POS) yang dibangun dengan framework Flutter. Aplikasi ini mengelola data produk, transaksi, dan data pengguna. Data disimpan secara lokal menggunakan database SQLite dan dapat disinkronkan dengan server REST API.';

  @override
  String get about_learningResource =>
      'Proyek ini berfungsi sebagai sumber belajar bagi pengembang Flutter yang ingin mempelajari tentang Clean Architecture, manajemen state Riverpod, navigasi GoRouter, dan integrasi database SQLite. Proyek ini bersumber terbuka dan tersedia di GitHub.';

  @override
  String get about_developedBy => 'Dikembangkan dengan ❤️ oleh';

  @override
  String get about_developerName => 'Fakhri Aditia Rahman';

  @override
  String get about_github => 'GitHub';

  @override
  String get about_website => 'Situs Web';

  @override
  String get welcome_title => 'Selamat Datang!';

  @override
  String get welcome_subtitle => 'Selamat datang di aplikasi Flutter POS';

  @override
  String get error_backToHome => 'Kembali ke beranda';

  @override
  String get shared_oops => 'Oops!';

  @override
  String get shared_somethingWrong => 'Terjadi kesalahan, silakan hubungi pengembang.';

  @override
  String get shared_close => 'Tutup';

  @override
  String get shared_nothingToShow => 'Tidak ada yang ditampilkan';

  @override
  String get shared_somethingWrongRetry => 'Terjadi kesalahan.\nSilakan coba lagi nanti.';
}
