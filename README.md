# ⚡️ iConventer - Ultra-Hızlı macOS Medya Çevirici

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?logo=apple)](https://github.com/Sahin1705/iConventer/releases)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)](https://swift.org)
[![Architecture](https://img.shields.io/badge/Architecture-Universal%202%20(Apple%20Silicon%20%2B%20Intel)-purple)](https://github.com/Sahin1705/iConventer/releases)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/Sahin1705/iConventer?color=brightgreen)](https://github.com/Sahin1705/iConventer/releases)

Apple Silicon (M1, M2, M3, M4, M5) ve Intel Mac'ler için özel olarak geliştirilmiş; **0.2 saniyede kayıpsız video remux** yapabilen, **HEIC fotoğrafları anında JPEG'e** çeviren, **%100 yerel (offline)** çalışan açık kaynaklı modern macOS medya dönüştürücüsü.

<p align="center">
  <a href="https://github.com/Sahin1705/iConventer/releases/download/v1.0.0/iConventer.dmg">
    <img src="https://img.shields.io/badge/İndir-iConventer.dmg%20(v1.0.0)-blue?style=for-the-badge&logo=apple" alt="iConventer İndir" height="45">
  </a>
</p>

---

## 💻 Tüm Mac Modelleriyle %100 Uyumlu (Universal 2)

iConventer, **Universal 2 Binary** mimarisiyle derlenmiştir ve piyasadaki tüm Mac cihazlarında doğal (native) donanım hızlandırmasıyla çalışır:

* **MacBook Air:** M1, M2, M3, M4, M5 ve Intel modelleri
* **MacBook Pro:** M1/M2/M3/M4 (Base, Pro, Max) ve Intel modelleri
* **Mac Studio:** M1 Max, M1 Ultra, M2 Max, M2 Ultra ve yeni nesiller
* **Mac mini, iMac ve Mac Pro** tüm seriler

---

## 🚀 Öne Çıkan Özellikler

### ⚡️ 0.2 Saniye Yıldırım Hızı Remux (Kayıpsız)
iPhone veya Mac ile kaydedilen MOV videoları zaten H.264/HEVC formatındadır. Çoğu çevirici videoyu baştan encode ederek 20-30 saniye harcarken, iConventer **Stream Passthrough (Remux)** teknolojisiyle kapsayıcıyı anında MP4 yapar.
* 150 MB MOV dosyasını **0.2 - 0.4 saniyede** MP4'e çevirir.
* Pikseller doğrudan kopyalandığı için **%0 kalite kaybı** yaşanır.

### 🍏 Donanım Motoru Entegrasyonu
* **Apple VideoToolbox:** Yeniden kodlama gereken durumlarda (ProRes vb.) doğrudan SoC donanım video kodlayıcılarını (`h264_videotoolbox`, `hevc_videotoolbox`) kullanır.
* **Apple ImageIO:** HEIC fotoğrafları SoC donanım görsel işleme çekirdekleriyle milisaniyeler içinde JPEG veya PNG'ye dönüştürür.
* **Çok Çekirdekli Paralel İşleme:** Mac'inizdeki tüm performans çekirdeklerini (Mac Studio Ultra'da 24 çekirdeğe kadar) eşzamanlı kullanarak yüzlerce dosyayı aynı anda çevirir.

### 🖱️ Finder Sağ Tık "Hızlı İşlem"
Herhangi bir dosyayı veya klasörü uygulamayı açmadan dönüştürün:
* Dosyaya sağ tıklayın ➔ **Hızlı İşlemler ➔ "iConventer ile Çevir"**.
* Dosyalar anında dönüştürme kuyruğuna aktarılır.

### 🔒 %100 Gizlilik ve Güvenlik
* Hiçbir dosyanız sunuculara veya buluta yüklenmez.
* İnternet bağlantısı gerektirmez, tamamen cihazınızda yerel çalışır.

---

## 🎬 Desteklenen Formatlar

| Tür | Kaynak | Hedef |
| :--- | :--- | :--- |
| **Görsel** | HEIC, HEIF, JPEG, PNG, WebP, TIFF, GIF, BMP, AVIF | JPEG, PNG, HEIC, WebP, TIFF |
| **Video** | MOV, MP4, MKV, WebM, AVI, M4V, FLV | MP4 (Remux • 0.2s), MP4 (H.264), MP4 (HEVC), MOV, WebM, GIF |
| **Ses** | MP3, M4A, WAV, AAC, FLAC, AIFF | MP3, M4A (AAC), WAV |

---

## 📥 Hazır Kurulum (.dmg)

1. [Releases sayfasından](https://github.com/Sahin1705/iConventer/releases) **`iConventer.dmg`** dosyasını indirin.
2. DMG dosyasını açıp **iConventer** uygulamasını **Applications (Uygulamalar)** klasörüne sürükleyin.
3. Sağ tık menüsünü aktifleştirmek için DMG içindeki **`Hızlı İşlemi Yükle.command`** dosyasına çift tıklayın.

---

## 🛠 Kaynak Koddan Derleme (Geliştiriciler İçin)

Gereksinimler: macOS 13.0+, Xcode Komut Satırı Araçları (`xcode-select --install`).

```bash
# Projeyi klonlayın
git clone https://github.com/Sahin1705/iConventer.git
cd iConventer

# Universal 2 uygulamasını derleyin (arm64 + x86_64)
./build.sh

# Şık bir DMG yükleyici paketi oluşturun
./create_dmg.sh
```

---

## 📄 Lisans
Bu proje [MIT Lisansı](LICENSE) kapsamında açık kaynaklı olarak paylaşılmaktadır. Özgürce kullanabilir, katkıda bulunabilir ve geliştirebilirsiniz.
EOF
