# PROJE ANA BELGE — CUDA GEMM Tırmanışı + Roofline

Bu belge projenin **kontrol merkezi**: ne yapıyoruz, neden yapıyoruz, şimdiye kadar ne yapıldı, bundan sonra ne var. Diğer beş plan dosyası (aşağıda) bunun detaylarıdır; kaybolduğunda buraya dön.

**Son güncelleme:** Faz 0 (Ölçüm Laboratuvarı) tamamen bitirildi. Ana projeye (GEMM Tırmanışı) geçiliyor.

---

## 1. Proje Nedir? (kapsam)

**Tek cümle:** CUDA'da matris çarpımını (GEMM) naif bir kernel'den başlayıp adım adım optimize ederek cuBLAS'a yaklaştırmak — ama asıl amaç hız değil, **her optimizasyonu ölçüp roofline üzerinde neden işe yaradığını gösterebilmek.**

**Bu bir öğrenme projesi.** Hedef çalışan bir kütüphane üretmek değil, GPU donanımını ölçüm ve optimizasyon üzerinden gerçekten anlamak. Çıktı: kod + ölçümler + "neden" açıklamaları + bir portföy reposu.

### Başarı tanımı (senin kriterin)
Her optimizasyon adımında:
1. Kernel'i doğru **ölçmüş**,
2. Roofline'da nereye düştüğünü **göstermiş**,
3. Bir önceki adıma göre noktanın neden o yöne kaydığını kendi cümlelerinle **açıklamış** olmak.

Sonunda tek bir roofline grafiğinde tüm tırmanışın ilerleyişini görebilmek.

### Kapsam sınırları (bilinçli kararlar)
- **Dahil:** GEMM tırmanışı (naif → coalescing → shared memory tiling → register tiling → vektörel erişim), her adımın ölçümü, roofline analizi.
- **Dahil (ön faz):** Ölçüm altyapısı ve kalibrasyon (Faz 0).
- **Hariç:** Ray tracer (başka bir sefere; bu proje sadece GEMM). Çok-GPU, tensor core'lar (opsiyonel ileri hedef), üretim-seviyesi kütüphane.
- **Donanım:** NVIDIA Tesla T4, Google Colab. (Jetson yok, yerel GPU yok — hepsi bulut.)
- **Tempo:** Haftada ~15 saat.

### Çalışma felsefesi
- **Olabildiğince az AI.** Kod yazdırma / hata düzelttirme yok; takılınca önce doküman + hata mesajı arama + minimal örnek. AI sadece 90 dk tıkanınca ipucu düzeyinde. (Detay: `bagimsiz-calisma-kiti.md`)
- **Ölç, tahmin etme.** Her deneyden önce tahmin yaz, sonra ölç; tahminin tutmadığı yer en çok öğrendiğin yer.
- **Tek değişken.** Bir seferde tek şey değiştir, yoksa neyin ne kattığını gösteremezsin.
- **Yazamıyorsan bilmiyorsundur.** Her adımın "neden"ini repoya yaz.

---

## 2. Belge Haritası (tüm plan dosyaları)

Bu proje boyunca oluşturduğumuz dosyalar ve rolleri:

| Dosya | Rol |
|---|---|
| **PROJE-ANA-BELGE.md** (bu dosya) | Kontrol merkezi: kapsam + durum + tüm yol haritası |
| `gpu-temel-sorular.md` | Başlamadan önce araştırılacak 11 temalık kavram soruları |
| `kaynaklar.md` | O soruların her temasına bir öğrenme kaynağı (linkli) |
| `faz0-olcum-laboratuvari.md` | **Faz 0** (3 hafta): ölçüm terazisini kurma detaylı planı |
| `gemm-haftalik-kilavuz.md` | **Ana proje** (8 hafta): GEMM tırmanışı, hafta hafta, linkli |
| `bagimsiz-calisma-kiti.md` | Takılınca başvuru: hata ayıklama akışı, doğrulama, topluluklar |

---

## 3. Bu Projeye Nasıl Geldik? (karar geçmişi)

1. **Hardware yönü** seçildi (yazılım/oyun yerine donanım).
2. Donanım içinde **GPU / CUDA** seçildi.
3. Amaç **derinlemesine öğrenme / teori** olarak belirlendi (portföy ya da hız değil).
4. Elde Jetson olmadığı, sadece Raspberry Pi 3 + Pixhawk olduğu ortaya çıktı → bunlar CUDA'ya uygun değil → **Colab (T4 GPU)** platform olarak seçildi.
5. İki aday proje tartışıldı: **GEMM tırmanışı** (derinlik, bellek hiyerarşisi) ve **ray tracer** (yürütme modeli, görsel).
6. **GEMM tırmanışı + roofline** seçildi; ray tracer kapsam dışı bırakıldı.
7. Ölçümü önce öğrenme kararı alındı → GEMM'den önce bir **Faz 0 (ölçüm laboratuvarı)** eklendi.
8. Mümkün olduğunca az AI ile ilerleme kararı → bağımsız çalışma kiti hazırlandı.

---

## 4. Şimdiye Kadar Ne Yapıldı? (tamamlanan iş)

### Hazırlık (planlama)
- [x] Kavram temeli: 11 temalık soru listesi + kaynakları çalışıldı.
- [x] Faz 0 ve GEMM planları, bağımsız çalışma kiti hazırlandı.

### Faz 0 — Ölçüm Laboratuvarı Tamamlandı ✅
- [x] **Hafta 1 / Gün 1-2:** Ortam ve donanım keşfi. `device_query.cu` ve `bandwidth_test.cu` yazılarak T4 sınırları (320.06 GB/s, 8.14 TFLOP/s, Sırt Noktası: 25.43) hesaplandı ve kalibre edildi.
- [x] **Hafta 1 / Gün 3-5:** Zamanlama ve metrik altyapısı inşa edildi. `timing.cuh` ve `metrics.cuh` başlık dosyaları, testleri (`metrics_test.cu`) ile birlikte eklendi. Warm-up mantığı doğrulandı.
- [x] **Hafta 2:** Kalibrasyon kernel'leri yazıldı. SAXPY (`saxpy_test.cu`) ve FMA (`fma_test.cu`) kullanılarak roofline modeli çıkarıldı ve `plots/faz0_kalibrasyon_roofline.png` olarak belgelendi.
- [x] **Hafta 3:** Stres testleri (`sweep_size.cu`, `sweep_block.cu`, `sweep_stride.cu`) çalıştırılarak problem boyutu, blok yapısı ve stride değişimlerinin sisteme etkileri ölçüldü. Tüm kavramsal metrik haritası belgelendi (`notes/` klasörü).

---

## 5. Şimdi Neredeyiz?

**Faz 0 (Ölçüm Laboratuvarı) başarıyla bitirildi.** 
Şu an sistemin teorik ve pratik donanım kapasitesi biliniyor ve ölçüm terazimiz kalibre edilmiş durumda. Sıradaki durağımız: **Ana Proje (GEMM Tırmanışı) - Hafta 2 (Naif GEMM).** Faz 0 içinde, GEMM rehberindeki Hafta 1 gereksinimleri halledildiği için doğrudan asıl optimizasyon tırmanışına geçiyoruz.

---

## 6. Bundan Sonra Ne Var? (kalan yol haritası)

### ANA PROJE — GEMM Tırmanışı (8 hafta)
Detay: `gemm-haftalik-kilavuz.md`.

- **Hafta 2 — Naif GEMM:** baseline + cuBLAS "tavanı" + doğruluk kontrolü altyapısı. Memory-bound çıkışını doğrula. ⬅️ SIRADA
- **Hafta 3 — Global memory coalescing:** erişim desenini düzelt. Hipotez: nokta *yukarı* kayar (AI sabit, bandwidth artar).
- **Hafta 4 — Shared memory tiling:** en önemli adım. Hipotez: nokta ilk kez *sağa* kayar (AI artar).
- **Hafta 5 — 1D block tiling:** register'da yeniden kullanım + occupancy takası.
- **Hafta 6 — 2D block tiling:** dönüm noktası. Hipotez: sırt noktasını *geçer* (compute-bound'a dönüşür).
- **Hafta 7 — Vektörel erişim + bank conflict:** float4 + padding, ince ayar.
- **Hafta 8 — Sentez:** birleşik roofline grafiği + tablo + teknik yazı + README.

---

## 7. Genel Bitiş Tanımı (tüm proje)

Proje şu üçü sağlanınca biter:
1. Naif'ten float4'e ~7 kernel'lik, doğruluğu kanıtlanmış bir GEMM ailesi.
2. Tek bir roofline grafiğinde tüm tırmanışın görsel ilerleyişi (sol-alttan sağ-yukarıya).
3. Her adımı "neden işe yaradı"sıyla açıklayan teknik yazı + derlenebilir, README'li repo.

Asıl kazanım: herhangi bir CUDA kernel'ine uygulayabileceğin **ölç–anla–göster** düşünce çerçevesi.

---

## 8. Her Oturum Başı Hatırlatması

1. Colab → T4 GPU seçili mi? `!nvidia-smi` ile doğrula.
2. Kurulum hücresini çalıştır: repoyu klonla → `git config` → token ayarla → `mkdir -p build`.
3. O günün hedefini yaz (tek cümle: bugün neyi ölçeceğim/değiştireceğim).
4. Oturum sonunda: ne ölçtüm / ne bekliyordum / ne çıktı / neden farklı → `notes/`e yaz.
5. Çalışan her sürümü commit + push; anlamlı adımları `git tag`'le.
6. Runtime silmeden önce `git status` temiz mi kontrol et.
