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

## Deney 2 — warm-up'lı vs warm-up'sız

### Tahmin (ölçmeden önce)
warmup=0 ilk-çağrı şişkinliğini ölçüme katar → çok daha büyük çıkar;
warmup=10 şişkinliği dışarıda bırakır → küçük. Belki birkaç kat fark.

### Ölçüm (iki ayrı program, her biri taze/soğuk süreç)
| Ölçüm | Süre |
|---|---|
| warmup=0,  iter=1 | 2.2734 ms |
| warmup=10, iter=1 | 2.2416 ms |

Fark ~%1 → yok denecek kadar az. **Tahmin tutmadı.**

### Neden fark yok? (asıl ders)
İlk-çağrı şişkinliği "ilk memcpy"ye değil, "programdaki ilk CUDA işi"ne aittir.
Programda repeat'ten ÖNCE cudaMalloc + cudaMemset çalıştı; context kurulumu /
sürücü hazırlığı orada ödendi. repeat'e girildiğinde GPU zaten ısınmıştı, bu
yüzden memcpy seviyesinde warmup fark yaratmadı — şişkinliği cudaMalloc soğurdu.

### O zaman warm-up gereksiz mi? HAYIR
- Bu deneyde şişkinliği başka bir çağrı (cudaMalloc) maskeledi. İlk CUDA işi
  doğrudan memcpy olsaydı warmup=0 dramatik büyük çıkardı.
- İlk-çağrı maliyetinin kaynakları: context/sürücü kurulumu, kodun GPU'ya
  yüklenmesi, GPU'nun düşük güç modundan tam saate çıkması. Warm-up bunları
  ölçüm dışında tutar.

### Çapraz doğrulama
Bu iki sayı (2.27 / 2.24 ms), Deney 1'in C ölçümü (2.24 ms) ve repeat
terazisinin kopya-başına süresi (2.221 ms) ile birebir uyuşuyor. Üç bağımsız
ölçüm aynı "ısınmış memcpy" süresini veriyor → terazi tutarlı ve sağlam.

### Gün 3-4 sonucu
Terazi (repeat) kuruldu, 241.81 GB/s ile doğrulandı. İki deney de yapıldı:
"neden CPU timer yanlış" (Deney 1) ve "neden warm-up" (Deney 2) açıklamaları yazıldı.
