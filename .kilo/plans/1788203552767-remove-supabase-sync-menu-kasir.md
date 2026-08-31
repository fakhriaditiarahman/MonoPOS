# Plan: Hilangkan Menu Supabase Sync dari Pengaturan untuk Role Kasir

## Context

- `_SupabaseConfigButton` di `account_screen.dart:46` menampilkan tombol "Supabase Sync" pada halaman Account/Pengaturan.
- Tidak ada guard role pada widget ini — tombol terlihat dan bisa diklik oleh semua role, termasuk `kasir`.
- Semua tombol pengaturan lain (`_StoreSettingsButton`, `_RevenueButton`, `_PaymentSettingsButton`, `_ProductDataButton`, `_EmployeeManagementButton`) sudah punya guard `isAdmin` dan mengembalikan `SizedBox.shrink()` untuk non-admin.
- Tombol `_SyncButton` di `home_screen.dart` (app bar) **tidak termasuk scope** — itu trigger sync runtime, bukan menu pengaturan.

## Decision

Tambahkan guard `isAdmin` ke `_SupabaseConfigButton` dengan pola yang sama persis seperti tombol pengaturan lainnya.

## Steps

1. **Edit `lib/presentation/screens/account/account_screen.dart`**
   - Di `_SupabaseConfigButton.build()` (baris 707), tambahkan:
     ```dart
     final isAdmin = ref.watch(authNotifierProvider.select((s) => s.user?.role?.value == 'admin'));
     if (!isAdmin) return const SizedBox.shrink();
     ```
     sebelum baris yang mengembalikan `Padding`.
   - Hasilnya tombol "Supabase Sync" hanya tampil untuk role `admin`; untuk `kasir` (dan role lain) mengembalikan widget kosong.

## Validation

- Jalankan `dart format lib/presentation/screens/account/account_screen.dart --line-length=120`
- Jalankan `flutter analyze lib/presentation/screens/account/account_screen.dart` untuk memastikan tidak ada error
- Login sebagai kasir, buka halaman Account → tombol "Supabase Sync" harus tidak terlihat
- Login sebagai admin, buka halaman Account → tombol "Supabase Sync" tetap terlihat dan berfungsi
