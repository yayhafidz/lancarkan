<div align="center">
  <img src="assets/logo/icon.png" width="120" alt="Lancarkan Logo"/>

# Lancarkan

**Aplikasi Mock Location GPS berbasis Flutter untuk Android.**

<p>
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Android-success?style=for-the-badge" alt="Android">
</p>

</div>

---

## 📖 Tentang

**Lancarkan** adalah aplikasi **Mock Location GPS** berbasis Flutter yang digunakan untuk mensimulasikan lokasi perangkat Android.

Aplikasi ini ditujukan untuk kebutuhan seperti:

- Pengujian aplikasi berbasis lokasi
- Pengembangan aplikasi geolokasi
- Simulasi perpindahan GPS
- Penggunaan lain yang memerlukan perubahan lokasi perangkat

Aplikasi menggunakan akses **root** untuk mengubah lokasi perangkat dan tidak bergantung pada fitur **Mock Location** di Developer Options Android.

---

## ✨ Fitur

- 🗺️ Menampilkan peta menggunakan **OpenStreetMap**
- 📍 Mengubah lokasi GPS perangkat
- 🚗 Simulasi pergerakan berdasarkan rute
- 🔄 Mendukung background service
- 🌙 Mendukung tema terang dan gelap
- ⚡ Dibangun menggunakan Flutter

---

## 📱 Persyaratan

Sebelum menjalankan aplikasi, pastikan perangkat memenuhi persyaratan berikut:

- Android
- Perangkat telah di-root
- Magisk (disarankan)
- SmaliPatcher Module
- Flutter SDK (untuk pengembangan)

> **Catatan**
>
> Aplikasi ini tidak menggunakan fitur **Mock Location** bawaan Android.

---

## 🚀 Instalasi

Clone repository

```bash
git clone https://github.com/yayhafidz/lancarkan.git
```

Masuk ke folder project

```bash
cd lancarkan
```

Install dependency

```bash
flutter pub get
```

Jalankan aplikasi

```bash
flutter run
```

---

## 📦 Dependencies

| Package | Keterangan |
|---------|------------|
| `flutter_map` | Menampilkan peta OpenStreetMap |
| `provider` | State management |
| `geolocator` | Mengakses lokasi perangkat |
| `shared_preferences` | Menyimpan konfigurasi aplikasi |

---

## ⚠️ Disclaimer

Aplikasi ini dibuat untuk kebutuhan pengembangan, pengujian, dan pembelajaran.

Pengguna bertanggung jawab atas penggunaan aplikasi ini serta memastikan penggunaannya sesuai dengan hukum dan kebijakan layanan yang berlaku.

---

## 🤝 Kontribusi

Kontribusi sangat terbuka.

Silakan membuat:

- Issue
- Pull Request
- Saran fitur
- Laporan bug

---

<div align="center">

Fueled by ☕

</div>
