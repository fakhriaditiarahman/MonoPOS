# Doku Payment Gateway - SNAP QRIS Integration

Integrasi payment gateway **Doku SNAP QRIS** untuk menerima pembayaran QRIS di MonoPOS.

## Table of Contents

- [Overview](#overview)
- [Arsitektur](#arsitektur)
- [Flow Pembayaran](#flow-pembayaran)
- [Konfigurasi](#konfigurasi)
- [API Endpoints](#api-endpoints)
- [Signature Generation](#signature-generation)
- [Mock Mode](#mock-mode)
- [File Structure](#file-structure)

---

## Overview

MonoPOS terintegrasi dengan Doku SNAP QRIS untuk menerima pembayaran nontunai via QRIS. Sistem ini mendukung:

- **Generate QRIS** - Membuat QR code pembayaran
- **Query Status** - Mengecek status pembayaran secara otomatis (polling) dan manual
- **Cancel QRIS** - Membatalkan QRIS yang belum dibayar
- **Refund** - Memproses pengembalian dana
- **Decode QRIS** - Mendekode data QR dari scanner

---

## Arsitektur

```
CartPanelFooter (UI)
  │
  ▼
HomeNotifier.createQrisTransaction()
  │
  ▼
DokuPaymentNotifier
  │
  ├── DokuPaymentService.generateQris()
  ├── DokuPaymentService.queryQrisStatus()   ← polling
  ├── DokuPaymentService.cancelQris()
  └── DokuPaymentService.refundQris()
  │
  ▼
Doku SNAP API (Sandbox/Production)
```

### Layer

| Layer | File | Responsibility |
|-------|------|----------------|
| UI | `doku_payment_screen.dart` | Menampilkan QR, timer, status |
| Provider | `payment_notifier.dart` | State management, polling logic |
| State | `payment_state.dart` | State model |
| Service | `doku_payment_service.dart` | HTTP calls ke Doku API, crypto signing |
| Settings | `payment_settings_screen.dart` | Konfigurasi credentials |
| Settings Provider | `payment_settings_notifier.dart` | Simpan/load settings |

---

## Flow Pembayaran

### 1. Inisiasi Pembayaran

```
User pilih QRIS → CartPanelFooter → HomeNotifier.createQrisTransaction()
  → DokuPaymentNotifier.startDokuPayment()
    → Save transaction (status: pending)
    → DokuPaymentService.generateQris()
    → Print QR slip ke printer
    → Start polling status
```

### 2. Polling Status

```
Auto-poll: 3x percobaan, interval 15 detik
  → DokuPaymentService.queryQrisStatus()
    → 'paid'    → _onPaymentSuccess() → update status → cetak struk → navigasi ke detail
    → 'pending' → lanjut polling
    → 'failed'  → tampilkan error

Manual poll: Tombol "Cek Pembayaran" muncul setelah auto-poll selesai
Timeout: 30 menit (1800 detik)
```

### 3. Pembatalan

```
User tekan tombol close → Dialog konfirmasi
  → DokuPaymentService.cancelQris()
  → Hapus state
```

### 4. Refund

```
DokuPaymentService.refundQris()
  → Kirim request dengan originalPartnerReferenceNo, partnerRefundNo, refundAmount
```

---

## Konfigurasi

### Akses Settings

Navigasi: **Akun → Pengaturan Doku**

### Fields yang Diperlukan

| Field | Keterangan | Contoh |
|-------|-----------|--------|
| **Client ID** | X-PARTNER-ID dari Doku Dashboard | `PARTNER-12345` |
| **Client Secret** | Secret Key untuk HMAC signing | `Secret key dari dashboard` |
| **Merchant ID** | ID Merchant Doku | `MERCHANT-001` |
| **Terminal ID** | ID terminal POS | `POS-001` |
| **RSA Private Key** | Private key RSA untuk B2B token signing | PEM format (PKCS#1 atau PKCS#8) |
| **Sandbox Mode** | Toggle sandbox/production | `true` untuk testing |

### Keys di SharedPreferences

```dart
Constants.dokuClientId      = 'doku_client_id'
Constants.dokuClientSecret   = 'doku_client_secret'
Constants.dokuMerchantId     = 'doku_merchant_id'
Constants.dokuTerminalId     = 'doku_terminal_id'
Constants.dokuPrivateKey     = 'doku_private_key'
Constants.dokuIsSandbox      = 'doku_is_sandbox'
```

### Base URL

| Mode | Base URL |
|------|----------|
| Sandbox | `https://api-sandbox.doku.com` |
| Production | `https://api.doku.com` |

---

## API Endpoints

### 1. Get Access Token (B2B)

**POST** `{baseUrl}/authorization/v1/access-token/b2b`

Authorization B2B menggunakan RSA signature.

**Request Headers:**
```
X-SIGNATURE: <RSA-SHA256 signature of "$clientId|$timestamp">
X-TIMESTAMP: <ISO8601 UTC timestamp>
X-CLIENT-KEY: <clientId>
Content-Type: application/json
```

**Request Body:**
```json
{
  "grantType": "client_credentials"
}
```

**Response (success):**
```json
{
  "responseCode": "2007300",
  "accessToken": "...",
  "expiresIn": 900
}
```

**Token caching:** Token di-cache di memory dan di-refresh otomatis sebelum expiry (default 900 detik).

---

### 2. Generate QRIS (QR MPM Generate)

**POST** `{baseUrl}/snap-adapter/b2b/v1.0/qr/qr-mpm-generate`

**Request Body:**
```json
{
  "partnerReferenceNo": "12345",
  "amount": {
    "value": "50000.00",
    "currency": "IDR"
  },
  "merchantId": "MERCHANT-001",
  "terminalId": "POS-001",
  "validityPeriod": "2026-07-14T03:22:00Z",
  "additionalInfo": {
    "postalCode": "00000",
    "feeType": "1"
  }
}
```

**Response (success):**
```json
{
  "responseCode": "2002600",
  "qrContent": "0002010102...",
  "referenceNo": "REF-001",
  "terminalId": "POS-001"
}
```

**Response codes:**
- `2002600` — Success
- Lainnya — Gagal

---

### 3. Query Status QRIS (QR MPM Query)

**POST** `{baseUrl}/snap-adapter/b2b/v1.0/qr/qr-mpm-query`

**Request Body:**
```json
{
  "originalPartnerReferenceNo": "12345",
  "originalReferenceNo": "REF-001",
  "serviceCode": "47",
  "merchantId": "MERCHANT-001"
}
```

**Response codes (`latestTransactionStatus`):**
| Code | Status | Keterangan |
|------|--------|-----------|
| `00` | `paid` | Pembayaran berhasil |
| `03` | `pending` | Masih menunggu |
| `06` | `failed` | Pembayaran gagal |
| Lainnya | `pending` | Asumsi masih menunggu |

---

### 4. Cancel QRIS (QR Expire)

**POST** `{baseUrl}/snap-adapter/b2b/v1.0/qr/qr-expire`

**Request Body:**
```json
{
  "partnerReferenceNo": "12345",
  "referenceNo": "REF-001",
  "merchantId": "MERCHANT-001",
  "reason": "Cancelled by merchant"
}
```

**Response (success):**
```json
{
  "responseCode": "2002800",
  "responseMessage": "Successful"
}
```

---

### 5. Refund QRIS (QR MPM Refund)

**POST** `{baseUrl}/snap-adapter/b2b/v1.0/qr/qr-mpm-refund`

**Request Body:**
```json
{
  "merchantId": "MERCHANT-001",
  "originalPartnerReferenceNo": "12345",
  "originalReferenceNo": "REF-001",
  "partnerRefundNo": "REFUND-001",
  "refundAmount": {
    "value": "50000.00",
    "currency": "IDR"
  },
  "reason": "Customer request",
  "additionalInfo": {
    "approvalCode": "APPROVAL-CODE"
  }
}
```

---

### 6. Decode QRIS (QR MPM Decode)

**POST** `{baseUrl}/snap-adapter/b2b/v1.0/qr/qr-mpm-decode`

Digunakan untuk mendekode data QR dari customer scanner.

**Request Body:**
```json
{
  "partnerReferenceNo": "12345",
  "qrContent": "0002010102...",
  "scanTime": "2026-07-14T02:30:00Z"
}
```

---

## Signature Generation

### RSA Signature (untuk Get Token)

```
stringToSign = "$clientId|$timestamp"
signature = RSA-SHA256(stringToSign, privateKey)
```

Mendukung format key: **PKCS#1** dan **PKCS#8**.

### HMAC-SHA512 Signature (untuk API calls lainnya)

```
hexBody = SHA256(requestBody)
stringToSign = "POST:$endpointUrl:$accessToken:$hexBody:$timestamp"
signature = HMAC-SHA512(clientSecret, stringToSign)
```

### Request Headers (semua API calls)

```
Content-Type: application/json
X-PARTNER-ID: <clientId>
X-EXTERNAL-ID: <timestamp_millis><random_5_digits>
X-TIMESTAMP: <ISO8601 UTC timestamp>
X-SIGNATURE: <HMAC-SHA512 signature>
Authorization: Bearer <accessToken>
CHANNEL-ID: H2H
```

---

## Mock Mode

Ketika credentials **tidak terisi** (Client ID, Client Secret, atau Merchant ID kosong), service otomatis menggunakan **mock mode**:

- **generateQris** → Mengembalikan QR mock, payment otomatis "paid" setelah 30 detik
- **queryStatus** → Return "paid" setelah 30 detik pertama
- **cancelQris** → Berhasil tanpa API call
- **refundQris** → Berhasil dengan mock response
- **decodeQris** → Mengembalikan data mock

Mock mode berguna untuk development dan testing tanpa koneksi ke Doku API.

---

## File Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── constants.dart                      # SharedPreferences keys
│   └── services/payment/
│       └── doku_payment_service.dart           # Service layer (API + mock)
├── presentation/
│   ├── providers/payment/
│   │   ├── payment_notifier.dart               # Payment state management
│   │   └── payment_state.dart                  # Payment state model
│   ├── providers/account/
│   │   ├── payment_settings_notifier.dart      # Settings state management
│   │   └── payment_settings_state.dart         # Settings state model
│   └── screens/
│       ├── payment/
│       │   └── doku_payment_screen.dart        # QR display + polling UI
│       ├── account/
│       │   └── payment_settings_screen.dart    # Doku configuration UI
│       └── home/components/
│           └── cart_panel_footer.dart          # Trigger pembayaran QRIS
```

---

## Error Handling

| Error | Handling |
|-------|----------|
| Token gagal | `Result.failure` dengan pesan error |
| Generate QRIS gagal | Transaksi dihapus dari DB |
| Polling timeout (30 menit) | Status → `failed`, timer berhenti |
| API error (HTTP != 200) | `Result.failure` dengan status code + body |
| Doku error code (bukan success) | `Result.failure` dengan `responseMessage` |
| Network exception | `Result.failure` dengan `toString()` |

---

## Response Code Reference

| Code | Endpoint | Keterangan |
|------|----------|-----------|
| `2007300` | Access Token | Token berhasil |
| `2002600` | QR Generate | QRIS berhasil dibuat |
| `2002400` | QR Payment | Pembayaran berhasil |
| `2002500` | QR Decode | Decode berhasil |
| `2002800` | QR Expire/Refund | Cancel/Refund berhasil |
