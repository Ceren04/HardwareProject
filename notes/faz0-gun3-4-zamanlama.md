# Faz 0 — Gün 3-4: Zamanlama Altyapısı

## Yeniden kullanılabilir terazi (repeat)
Timing bloğu (warm-up + tekrar + ortalama + CUDA events) bir template
fonksiyona taşındı. Ölçülecek iş lambda ile dışarıdan veriliyor, böylece
memcpy/kernel fark etmeksizin aynı fonksiyonla ölçülebiliyor.
Doğrulama: repeat ile D2D memcpy → 241.76 GB/s. bandwidthTest'in 241.81
sonucuyla birebir → terazi sağlam.

## Deney 1 — CPU saati vs CUDA events

### Tahmin (ölçmeden önce)
- A (CPU, sync yok): kısa çıkar, çünkü asenkron launch'ta CPU işi kuyruğa
  atıp beklemeden devam eder; kopyalamayı değil kuyruğa-atmayı ölçer.
- B (CPU, sync var): uzun çıkar, çünkü cudaDeviceSynchronize CPU'yu GPU
  bitene kadar bekletir; gerçek kopyalama süresini yakalar.
- C (events): beklemeye bakmadan GPU'nun gerçek süresini ölçer.
- Beklenti: A çok küçük; B ile C birbirine yakın ve büyük.

### Ölçüm
| Ölçüm | Süre | Ne ölçüyor |
|---|---|---|
| A — CPU, sync yok | 11 us | kuyruğa atma (kopyalama değil) |
| B — CPU, sync var | 4419 us | gerçek kopyalama + CPU gürültüsü |
| C — CUDA events   | 2237 us | GPU'nun temiz gerçek süresi |

C, repeat terazisinden çıkan 2221 us/kopya ile birebir tutuyor.

### Yorum — her sayı neyi ölçüyor?
- **A neden en küçük:** Asenkron launch. CPU memcpy'yi GPU kuyruğuna atıp
  beklemeden bir sonraki satıra geçti. t1 okunduğunda GPU kopyalamaya yeni
  başlamıştı; bu yüzden 11 us kopyalamanın değil, "işi ısmarlama"nın süresi.
  A, kopyalama süresi hakkında yanıltıcı.
- **B neden büyük:** cudaDeviceSynchronize CPU'yu bariyerde beklettiği için
  t1, GPU gerçekten bitince okundu. Gerçek kopyalama süresini içeriyor.
- **B neden C'den de büyük (tahminimde "yakın" demiştim, tutmadı):** B, CPU
  tarafındaki senkronizasyon maliyetini ve chrono'nun duvar-saati gürültüsünü
  (bekleme döngüsü, OS araya girmesi) içine katıyor. Events ise GPU'nun kendi
  donanım zaman damgasını okur, bu ara gürültüyü hiç görmez → daha temiz.

### Sonuç: neden CUDA events?
GPU süresini CPU saatiyle ölçmek ya tamamen yanlış (sync yok → sadece kuyruğa
atma) ya da doğru-ama-şişkin (sync var → CPU gürültüsü karışır) sonuç verir.
Doğru VE temiz ölçüm için CUDA events şart. Terazi bu yüzden events kullanıyor.

### Tahminim tuttu mu?
- A << C: tuttu.
- B ≈ C: tutmadı — B, C'nin ~2 katı çıktı.
- Öğrenilen: sync'li CPU ölçümü doğru *mertebeyi* verir (kopyalama
  mikrosaniyeler değil milisaniyeler sürüyor) ama events kadar temiz değildir.
  "En sinsi tuzak" A: sync'i unutursan kernel'i imkansız hızlı sanırsın.
