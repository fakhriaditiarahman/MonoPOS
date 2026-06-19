# WORKFLOW Sistem POS - MonoPOS

## 1. Alur Autentikasi (Login / Logout)

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Splash Screen │────▶│ Cek Auth     │────▶│ Home Screen  │
│   (/)        │     │ (ada sesi?)  │     │  (/home)     │
└──────────────┘     └──────┬───────┘     └──────────────┘
                            │ Tidak
                     ┌──────▼───────┐
                     │ Login Screen │
                     │  (/login)    │
                     └──────┬───────┘
                            │
              ┌─────────────┼─────────────┐
              ▼                           ▼
   ┌──────────────────┐      ┌──────────────────┐
   │ Login Google     │      │ Login Email/Pass  │
   │ (Supabase Auth)  │      │ (Local Auth)      │
   └────────┬─────────┘      └────────┬──────────┘
            │                         │
            ▼                         ▼
   ┌──────────────────────────────────────────┐
   │ AuthNotifier → AuthRepository            │
   │ → Simpan sesi → Redirect ke /home        │
   └──────────────────────────────────────────┘
```

**Role pengguna:**
- **Admin** — Akses penuh (kelola produk, transaksi, pengaturan, laporan)
- **Kasir** — Akses kasir (POS, transaksi)

---

## 2. Alur Penjualan (POS / Kasir)

```
┌─────────────────────────────────────────────────────────┐
│                   HOME SCREEN (/home)                    │
│                                                          │
│  ┌─────────────────────┐   ┌──────────────────────────┐ │
│  │   Daftar Produk     │   │     Cart Panel           │ │
│  │   (Grid)            │   │  ┌────────────────────┐  │ │
│  │                     │   │  │ Header             │  │ │
│  │ • Tap produk →      │──▶│  │ (Nama pelanggan,   │  │ │
│  │   tambah ke keranjang│   │  │  tipe harga)       │  │ │
│  │                     │   │  ├────────────────────┤  │ │
│  │ • Scan barcode →    │──▶│  │ Body               │  │ │
│  │   cari & tambah     │   │  │ (Daftar item,      │  │ │
│  │                     │   │  │  qty, harga)        │  │ │
│  │ • Search produk     │   │  ├────────────────────┤  │ │
│  │                     │   │  │ Footer             │  │ │
│  └─────────────────────┘   │  │ (Total, metode     │  │ │
│                             │  │  bayar, checkout)   │  │ │
│                             │  └────────────────────┘  │ │
│                             └──────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 2a. Tambah Produk ke Keranjang

```
User tap produk / scan barcode
  ↓
HomeNotifier.addOrderedProduct()
  ↓
Cek apakah produk sudah ada di keranjang
  ├── Ya  → Tambah quantity (+1)
  └── Tidak → Tambah item baru ke orderedProducts
  ↓
Update state (total, jumlah item)
```

### 2b. Pilih Tipe Harga

```
User toggle tipe harga di Cart Panel Header
  ├── Retail  → Gunakan harga retail (price)
  └── Grosir  → Gunakan harga grosir (wholesalePrice)
  ↓
HomeNotifier.setSelectedPriceType()
  ↓
Update harga semua item di keranjang
```

### 2c. Pilih Satuan Produk (Multi-Unit)

```
Produk bisa punya banyak satuan:
  Contoh: Teh Botol
    ├── pcs  (base unit, harga: Rp 5.000)
    ├── pack (isi 6 pcs, harga: Rp 28.000)
    └── dus  (isi 24 pcs, harga: Rp 100.000)
  ↓
User pilih satuan saat menambah ke keranjang
  ↓
Harga & konversi stok otomatis menyesuaikan
```

---

## 3. Alur Checkout & Pembayaran

```
User tap tombol Checkout
  ↓
Pilih metode pembayaran
  ├── Cash
  │     ↓
  │   Input jumlah diterima (receivedAmount)
  │     ↓
  │   Hitung kembalian (returnAmount = receivedAmount - totalAmount)
  │     ↓
  │   Simpan transaksi
  │     ↓
  │   Cetak struk (opsional)
  │     ↓
  │   Selesai ✅
  │
  └── QRIS (Digital Payment)
        ↓
      ┌──────────────────────────────────────┐
      │ QRIS Payment Screen (/payment/qris)  │
      │                                       │
      │ 1. Buat invoice via Interactive API   │
      │ 2. Tampilkan QR Code                  │
      │ 3. Polling status pembayaran          │
      │    ├── Pending → Tunggu scan          │
      │    ├── Paid ✅ → Update transaksi     │
      │    └── Failed ❌ → Tampilkan error    │
      │ 4. Selesai → Cetak struk (opsional)   │
      └──────────────────────────────────────┘
```

### 3a. Simpan Transaksi (Detail)

```
HomeNotifier → CreateTransactionUsecase
  ↓
TransactionRepository.create()
  ↓
┌─ TransactionLocalDatasource.create() ✅ (SQLite)
│    ├── Insert Transaction
│    ├── Insert OrderedProducts (line items)
│    └── Update Product stock (kurangi stok)
│
├─ SyncService.isOnline?
│    ├── Ya  → TransactionRemoteDatasource.create() (Supabase)
│    │          ├── Sukses ✅ → Selesai
│    │          └── Gagal   → Queue action
│    └── Tidak → QueuedActionRepository.create() (simpan antrian)
│
└── Reset keranjang
```

---

## 4. Alur Manajemen Produk

```
┌────────────────────────────────────────────────────────┐
│              PRODUCTS SCREEN (/products)                 │
│                                                         │
│  • Daftar produk (grid, infinite scroll, search)        │
│  • Tap produk → Detail Produk                           │
│  • Tombol (+) → Tambah Produk Baru                      │
└───────────┬────────────────────────┬────────────────────┘
            ▼                        ▼
┌───────────────────┐    ┌───────────────────────────┐
│ Product Detail    │    │ Product Form (Create/Edit) │
│ (/products/:id)   │    │ (/products/product-create) │
│                   │    │ (/products/product-edit/:id)│
│ • Lihat detail    │    │                            │
│ • Edit produk     │───▶│ • Nama produk              │
│ • Hapus produk    │    │ • Harga retail & grosir    │
│                   │    │ • Stok                     │
└───────────────────┘    │ • Barcode                  │
                         │ • Satuan (multi-unit)      │
                         │ • Foto produk (upload S3)  │
                         │ • Deskripsi                │
                         └───────────────────────────┘
```

### 4a. CRUD Produk

```
Create:
  User isi form → ProductFormNotifier.createProduct()
  → CreateProductUsecase → ProductRepository.create()
  → Local (SQLite) + Remote (Supabase) / Queue

Update:
  User edit form → ProductFormNotifier.updateProduct()
  → UpdateProductUsecase → ProductRepository.update()
  → Local + Remote / Queue

Delete:
  User konfirmasi hapus → ProductDetailNotifier.deleteProduct()
  → DeleteProductUsecase → ProductRepository.delete()
  → Local + Remote / Queue
```

---

## 5. Alur Riwayat Transaksi

```
┌────────────────────────────────────────────────┐
│       TRANSACTIONS SCREEN (/transactions)       │
│                                                 │
│  • Daftar transaksi (list, infinite scroll)     │
│  • Search berdasarkan nama pelanggan            │
│  • Tap transaksi → Detail                       │
└──────────────────┬──────────────────────────────┘
                   ▼
┌──────────────────────────────────────────────┐
│  TRANSACTION DETAIL (/transactions/:id)       │
│                                               │
│  • Info transaksi (tanggal, pelanggan)        │
│  • Daftar produk yang dibeli                  │
│  • Total, metode bayar, status pembayaran     │
│  • Cetak ulang struk                          │
│  • Hapus transaksi                            │
└──────────────────────────────────────────────┘
```

---

## 6. Alur Sinkronisasi Data (Online/Offline)

```
┌──────────────────────────────────────────────────┐
│                 MODE SINKRONISASI                  │
│                                                    │
│  Auto (default)  ←→  Offline  ←→  Online           │
│  [WiFi icon]         [WiFi-off]    [WiFi icon]     │
│  (auto detect)       (paksa lokal) (paksa remote)  │
│                                                    │
│  Toggle: Tap ikon WiFi di AppBar                   │
└──────────────┬───────────────────────────────────┘
               ▼

Saat ONLINE:
  Write data → SQLite ✅ → Supabase ✅ → Selesai

Saat OFFLINE:
  Write data → SQLite ✅ → Queue action → Selesai

Saat KEMBALI ONLINE:
  ┌────────────────────────────────────────────────┐
  │ ProcessQueuedActionUsecase                      │
  │                                                 │
  │ Loop semua antrian (urut: critical, createdAt): │
  │   → Parse repository + method + param           │
  │   → Dispatch ke remote datasource:              │
  │     • user/createUser                           │
  │     • product/updateProduct                     │
  │     • transaction/createTransaction             │
  │     • ... dll                                   │
  │   → Sukses → Hapus dari antrian                 │
  │   → Gagal  → Biarkan (coba lagi nanti)          │
  └────────────────────────────────────────────────┘
```

---

## 7. Alur Cetak Struk (Thermal Printer)

```
User checkout / tap cetak ulang
  ↓
PrinterService.printReceipt()
  ↓
┌───────────────────────────────────────┐
│  Format Struk:                        │
│                                       │
│  ┌─────────────────────────────────┐  │
│  │  [Nama Toko]                    │  │
│  │  [Alamat Toko]                  │  │
│  │  ─────────────────────────────  │  │
│  │  Tanggal: 19/06/2026 10:30     │  │
│  │  Kasir: John                    │  │
│  │  Pelanggan: Budi               │  │
│  │  ─────────────────────────────  │  │
│  │  Teh Botol x3     Rp 15.000    │  │
│  │  (retail, pcs)                  │  │
│  │  Indomie x1 dus   Rp 100.000   │  │
│  │  (grosir)                       │  │
│  │  ─────────────────────────────  │  │
│  │  Total:           Rp 115.000   │  │
│  │  Bayar (Cash):    Rp 120.000   │  │
│  │  Kembali:         Rp   5.000   │  │
│  │  ─────────────────────────────  │  │
│  │  [QR Code QRIS (jika QRIS)]    │  │
│  │  [Footer text]                  │  │
│  └─────────────────────────────────┘  │
│                                       │
│  Koneksi printer:                     │
│  • USB / Bluetooth / BLE / Network    │
│  • Ukuran kertas: 58mm / 72mm / 80mm  │
└───────────────────────────────────────┘
```

---

## 8. Alur Pengaturan Akun

```
┌──────────────────────────────────────────┐
│          ACCOUNT SCREEN (/account)        │
│                                           │
│  ┌─────────────────────────────────────┐  │
│  │ 📋 Edit Profil     → /account/profile│ │
│  │ 🏪 Pengaturan Toko → /account/store  │ │
│  │ 🖨️ Pengaturan Printer → /account/...  │ │
│  │ 💳 Pengaturan Pembayaran → /account/..│ │
│  │ 📊 Laporan Pendapatan → /account/rev  │ │
│  │ ℹ️  Tentang          → /account/about │ │
│  │ 🚪 Logout                            │ │
│  └─────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

### 8a. Pengaturan Toko
- Nama toko, alamat, footer struk
- Disimpan di SharedPreferences

### 8b. Pengaturan Printer
- Scan & connect printer (USB/Bluetooth/BLE/Network)
- Pilih ukuran kertas (58mm/72mm/80mm)
- Test print

### 8c. Pengaturan Pembayaran
- API Key, Merchant ID, Merchant Name (Interactive QRIS)
- Toggle mock mode untuk development

---

## 9. Alur Laporan Pendapatan

```
┌──────────────────────────────────────────┐
│        REVENUE SCREEN (/account/revenue)  │
│                                           │
│  Pilih rentang tanggal                    │
│    ↓                                      │
│  RevenueNotifier.loadRevenue()            │
│    ↓                                      │
│  GetDailyRevenueUsecase                   │
│    ↓                                      │
│  Query transaksi berdasarkan tanggal      │
│    ↓                                      │
│  Tampilkan per hari:                      │
│  ┌─────────────────────────────────────┐  │
│  │ Tanggal    │ Transaksi │ Pendapatan │  │
│  │ 18/06/2026 │    15     │ Rp 2.5jt   │  │
│  │ 19/06/2026 │    23     │ Rp 4.1jt   │  │
│  │ ...        │    ...    │ ...        │  │
│  └─────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

---

## 10. Arsitektur Data (Database)

```
┌─────────┐       ┌─────────────┐       ┌────────────────┐
│  User   │──1:N──│  Product     │       │  ProductUnit   │
│         │       │             │──1:N──│  (multi-unit)   │
└────┬────┘       └──────┬──────┘       └────────────────┘
     │                   │
     │ 1:N               │ N:M (via OrderedProduct)
     │                   │
┌────▼────────────┐   ┌──▼──────────────┐
│  Transaction    │──1:N──│ OrderedProduct │
│                 │       │                │
│ • paymentMethod │       │ • quantity     │
│ • totalAmount   │       │ • priceType    │
│ • paymentStatus │       │ • unit         │
│ • paymentQR     │       │ • price        │
└─────────────────┘       └────────────────┘

┌──────────────┐
│ QueuedAction │  (offline sync queue)
│ • repository │
│ • method     │
│ • param JSON │
└──────────────┘
```

---

## 11. Stack Teknologi

| Komponen | Teknologi |
|----------|-----------|
| Framework | Flutter (Dart) |
| State Management | Riverpod (Notifier/State) |
| Routing | GoRouter |
| Database Lokal | SQLite (sqflite) |
| Backend Remote | Supabase |
| Autentikasi | Supabase Auth (Google + Email/Password) |
| Storage | S3-compatible (AWS Signature V4) |
| Pembayaran Digital | Interactive.co.id QRIS API |
| Printer | unified_esc_pos_printer (USB/BT/BLE/Network) |
| Arsitektur | Clean Architecture (5 layer) |
| Pattern | Result type, Usecase pattern, Offline-first |

---

## 12. Diagram Alur Data (Data Flow)

```
┌─────────────────────────────────────────────────────────────┐
│                       USER INTERFACE                         │
│   (Screens / Widgets via ConsumerWidget / ConsumerStatefulWidget) │
└──────────────────────────┬──────────────────────────────────┘
                           │ ref.read(notifierProvider)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                        NOTIFIER (Riverpod)                   │
│   • Menerima event UI & memanggil Usecase / Repository      │
│   • Mengelola State (Loading / Success / Error)             │
│   • Contoh: HomeNotifier, ProductsNotifier, AuthNotifier    │
└──────────────────────────┬──────────────────────────────────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
┌─────────────────────┐ ┌──────────┐ ┌─────────────────────┐
│  USECASE (Opsional)  │ │ LANGSUNG │ │        USECASE       │
│  (Kompleks > 1 repo) │ │ KE REPO  │ │  (Kompleks > 1 repo) │
│  Contoh:             │ │(Sederhana)│ │  Contoh:             │
│  ProcessQueuedAction │ │          │ │  GetDailyRevenue     │
│  UploadUserPhoto     │ │          │ │                      │
└──────────┬──────────┘ └────┬─────┘ └──────────┬──────────┘
           │                 │                  │
           ▼                 ▼                  ▼
┌──────────────────────────────────────────────────────────────┐
│                     REPOSITORY IMPL                           │
│  • Koordinasi Local Datasource + Remote Datasource            │
│  • Cek SyncService.isOnline untuk write                       │
│  • Queue action jika offline                                  │
└──────────┬──────────────────────────┬────────────────────────┘
           │                          │
           ▼                          ▼
┌─────────────────────┐   ┌─────────────────────────────┐
│ LOCAL DATASOURCE     │   │ REMOTE DATASOURCE            │
│ (SQLite)             │   │ (Supabase REST API)          │
│ • Read/Write lokal   │   │ • Read/Write remote          │
│ • Cepat, offline     │   │ • Untuk backup & multi-device│
└─────────────────────┘   └─────────────────────────────┘
```

---

## 13. Routing Map

```
/                          → SplashScreen
/login                     → LoginScreen
/error                     → ErrorScreen

/payment/qris              → QrisPaymentScreen (full-screen overlay)

ShellRoute (Bottom Navigation - MainScreen):
  /home                    → HomeScreen (POS kasir)
  /products                → ProductsScreen (daftar produk)
    /products/product-create          → ProductFormScreen (tambah)
    /products/product-edit/:id        → ProductFormScreen (edit)
    /products/product-detail/:id      → ProductDetailScreen
  /transactions            → TransactionsScreen (riwayat)
    /transactions/transaction-detail/:id → TransactionDetailScreen
  /account                 → AccountScreen (pengaturan)
    /account/profile                  → ProfileFormScreen
    /account/store-settings           → StoreSettingsScreen
    /account/printer-settings         → PrinterSettingsScreen
    /account/payment-settings         → PaymentSettingsScreen
    /account/revenue                  → RevenueScreen
    /account/about                    → AboutScreen
```

---

## 14. Skenario End-to-End (Kasir)

```
1. KASIR BUKA APLIKASI
   Splash → Cek sesi → Login (email/password atau Google)
     ↓
2. Home Screen (POS)
   - Pilih tipe harga (Retail/Grosir)
   - Ketik nama pelanggan (opsional)
     ↓
3. TAMBAH PRODUK KE KERANJANG
   - Tap produk dari grid → otomatis masuk keranjang
   - Atau scan barcode → produk ditemukan & ditambahkan
   - Ubah qty, pilih satuan jika multi-unit
     ↓
4. CHECKOUT
   - Pilih metode bayar
     ├── CASH: Input nominal diterima → hitung kembalian
     └── QRIS: Generate QR → pelanggan scan → polling status
     ↓
5. TRANSAKSI TERSIMPAN
   - Local SQLite ✅
   - Remote Supabase (jika online) / Queue (jika offline)
   - Stok produk berkurang
     ↓
6. CETAK STRUK (opsional)
   - Printer thermal → struk keluar
     ↓
7. RESET → Kembali ke step 2 untuk transaksi berikutnya
```

---

## 15. Skenario End-to-End (Admin)

```
1. ADMIN LOGIN
   Splash → Login dengan akun admin
     ↓
2. KELOLA PRODUK
   - Tambah produk baru (nama, harga, stok, barcode, foto, multi-unit)
   - Edit produk yang sudah ada
   - Hapus produk
     ↓
3. LIHAT TRANSAKSI
   - Riwayat transaksi (search, filter)
   - Detail transaksi
   - Cetak ulang struk
   - Hapus transaksi jika perlu
     ↓
4. PENGATURAN
   - Edit profil toko (nama, alamat, footer struk)
   - Setup printer thermal
   - Konfigurasi pembayaran QRIS
     ↓
5. LAPORAN PENDAPATAN
   - Pilih rentang tanggal
   - Lihat rekap harian (total transaksi, total pendapatan)
     ↓
6. KONTROL SINKRONISASI
   - Cek status: Auto / Online / Offline
   - Lihat antrian yang pending
   - Trigger sinkronisasi manual jika perlu
     ↓
7. LOGOUT
   - Hapus sesi → Kembali ke Login Screen
```
