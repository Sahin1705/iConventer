# 🍎 iConverter - Mac App Store Yayınlama Rehberi

Bu rehber, **iConverter** uygulamasını Apple Developer hesabınızla Mac App Store'a göndermek için adım adım yapmanız gerekenleri açıklar.

---

## 1. App Store Connect'te Uygulama Kaydı Açma

1. Tarayıcınızdan **[appstoreconnect.apple.com](https://appstoreconnect.apple.com)** adresine gidin ve Apple Developer hesabınızla giriş yapın.
2. **Apps (Uygulamalarım)** bölümüne girip sol üstteki **"+" (Yeni Uygulama)** butonuna tıklayın.
3. Açılan pencerede şu bilgileri girin:
   - **Platform:** `macOS`
   - **Ad:** `iConverter` *(Eğer iConverter ismi alınmışsa `iConverter: Ultra Medya Çevirici` yapabilirsiniz)*
   - **Birincil Dil:** `Türkçe` veya `İngilizce`
   - **Bundle ID:** Listeden `com.sahin.iconverter` seçin (eğer listede yoksa developer.apple.com > Identifiers bölümünden tek tıkla ekleyebilirsiniz).
   - **SKU:** `iconverter-mac-001`
   - **Kullanıcı Erişimi:** `Tam Erişim (Full Access)`
4. **Oluştur (Create)** butonuna basın.

---

## 2. Mağaza Bilgilerini Doldurma (Kopyala / Yapıştır)

### Fiyatlandırma
* **Fiyat:** `Ücretsiz (Free - 0 TL)`

### Kategori
* **Birincil Kategori:** `İzlenceler (Utilities)`
* **İkincil Kategori (İsteğe bağlı):** `Video`

### URL Bağlantıları
* **Gizlilik Politikası URL (Privacy Policy):**  
  `https://github.com/Sahin1705/iConverter/blob/main/PRIVACY.md`
* **Destek URL (Support URL):**  
  `https://github.com/Sahin1705/iConverter`

### Yaş Sınırı (Age Rating)
* Anket sorularının hepsine **"Hayır"** deyin (Şiddet, kumar, yetişkin içerik yok). Sonuç **4+** olacaktır.

### Tanıtım Metinleri
* **Alt Başlık (Subtitle):** `0.2s Remux & Fotoğraf Çevirici`
* **Anahtar Kelimeler (Keywords):**  
  `converter,mov to mp4,heic to jpeg,video çevirici,fotoğraf dönüştürücü,heic,remux,video converter,audio converter,media`
* **Açıklama (Description):**
```
iConverter, Mac kullanıcıları için özel olarak geliştirilmiş ultra-hızlı ve %100 yerel çalışan bir medya dönüştürücüsüdür.

ÖNE ÇIKAN ÖZELLİKLER:
• 0.2 Saniye Remux: iPhone ve Mac MOV videolarını kalite kaybı olmadan saliseler içinde MP4'e dönüştürün.
• HEIC to JPEG/PNG: Fotoğraflarınızı orijinal kalitesinde ve anında dönüştürün.
• Apple Silicon Donanım Hızlandırma: M1, M2, M3, M4, M5 ve Intel çiplerinin tüm gücünü kullanır.
• Finder Entegrasyonu: Dosyalarınıza sağ tıklayıp Hızlı İşlemler > iConverter ile Çevir seçeneğini kullanabilirsiniz.
• %100 Gizli ve Güvenli: Hiçbir dosyanız internete veya buluta yüklenmez, tüm işlemler tamamen cihazınızda gerçekleşir.
```

---

## 3. Uygulamayı App Store'a Yükleme (2 Yöntem)

### Yöntem A: Xcode ile Tek Tıkla (En Kolay)
1. `/Users/misa/Desktop/iConverter/iConverter.xcodeproj` dosyasını Xcode ile açın.
2. Üst menüden **Product ➔ Archive** seçeneğine tıklayın.
3. Arşivleme bittiğinde açılan pencerede sağdaki mavi **"Distribute App"** butonuna basın.
4. **"App Store Connect"** seçip **"Upload"** deyin.
5. Xcode otomatik olarak sertifikalarınızı imzalar ve uygulamayı doğrudan App Store Connect hesabınıza yükler!

### Yöntem B: Hazır Script ile
Terminalden şu komutu çalıştırmanız yeterlidir:
```bash
cd /Users/misa/Desktop/iConverter
./package_for_appstore.sh
```
Bu script arşivi oluşturur ve yükleme penceresini otomatik olarak ekranınıza getirir.

---

## 4. İncelemeye Gönderme (Submit for Review)
Build yüklendikten 5-10 dakika sonra App Store Connect sayfanızda görünür. Sayfadaki **"İncelemeye Gönder (Submit for Review)"** butonuna bastığınızda Apple 24-48 saat içinde uygulamanızı onaylayıp dünya çapında Mac App Store'da yayına alır! 🚀
