# ⚡️ iConventer - Apple Silicon Ultra-Hızlı Medya Çevirici

Apple Silicon (M-Serisi) için özel olarak geliştirilmiş, tamamen yerel (offline) çalışan, donanım hızlandırmalı ve **0.2 saniye süper hızlı remux** destekli modern macOS medya dönüştürücü.

---

## 🚀 Öne Çıkan Özellikler

- **0.2 Saniye Yıldırım Hızı Remux (Kayıpsız):**
  - iPhone ve Mac MOV videolarını (`H.264/HEVC`) sıfırdan encode etmeden doğrudan MP4 kapsayıcısına aktarır.
  - 150 MB'lık bir videoyu **0.2 - 0.4 saniyede** kalite kaybı olmadan MP4'e çevirir.
- **Apple Silicon M-Serisi Donanım Hızlandırma:**
  - VideoToolbox donanım motorları (`h264_videotoolbox`, `hevc_videotoolbox`, `ProRes`).
  - ImageIO SoC donanım dekoderi ile HEIC fotoğrafları milisaniyeler içinde JPEG/PNG'ye dönüştürür.
  - Çok çekirdekli paralel işleme ile yüzlerce dosyayı aynı anda dönüştürür.
- **Finder Sağ Tık / Hızlı İşlem Entegrasyonu:**
  - Finder'da herhangi bir dosyaya veya klasöre sağ tıklayıp **Hızlı İşlemler > "iConventer ile Çevir"** diyerek tek tıkla dönüştürme kuyruğuna alabilirsiniz.
- **%100 Yerel ve Gizli:** Hiçbir dosyanız internete çıkmaz, her şey cihazınızda yerel çalışır.
- **Sürükle & Bırak:** Dosyaları, klasörleri veya Dock simgesine sürükleyip bırakabilirsiniz.

---

## 📦 Kurulum ve DMG Paketi

Masaüstünüzde hazır bulunan **`iConventer.dmg`** dosyasını açıp uygulamayı `Applications` (Uygulamalar) klasörüne sürüklemeniz yeterlidir.

### Finder Sağ Tık "Hızlı İşlem" Özelliği
Uygulama zaten sisteminize bu özelliği ekledi. Yeni bir Mac'e kurarken DMG içerisindeki **`Hızlı İşlemi Yükle.command`** dosyasına çift tıklayarak sağ tık menüsünü anında aktifleştirebilirsiniz.

---

## 🛠 Geliştirici Komutları

Yeniden derlemek için:
```bash
./build.sh
```

Yeni bir `.dmg` yükleyicisi oluşturmak için:
```bash
./create_dmg.sh
```
