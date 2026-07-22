# Donanım: NVIDIA Tesla T4

Colab, `deviceQuery` çıktısından (src/faz0/device_query.cu), 2026-07-22.

## Okunan değerler

| Özellik | Değer |
|---|---|
| Kart | Tesla T4 |
| Compute capability | 7.5 (sm_75, Turing) |
| SM sayısı | 40 |
| Warp boyutu | 32 |
| SM başına maks. thread | 1024 |
| Shared memory / blok | 49152 bayt (48 KB) |
| Shared memory / SM | 65536 bayt (64 KB) |
| Register / SM | 65536 adet (32-bit) |
| Global bellek | 14.56 GB |
| SM saati | 1590 MHz |
| Bellek saati | 5001 MHz |
| Bellek veri yolu | 256 bit |

## Türetilen değerler

**Teorik bellek bant genişliği:** 320.06 GB/s
Hesap: 5001 MHz × 2 (GDDR6 çift veri hızı) × 256 bit / 8 = 320.06 GB/s

**Teorik tepe FP32:** 8.14 TFLOP/s
Hesap: 40 SM × 64 FP32 çekirdek/SM × 1590 MHz × 2 (FMA) = 8140.8 GFLOP/s = 8.14 TFLOP/s

**Sırt noktası (ridge point):** 25.43 FLOP/byte
Hesap: tepe FLOPS / tepe bant genişliği

Bu eşiğin altındaki aritmetik yoğunluk → memory-bound, üstü → compute-bound.

## Pratik tavan

**Ölçülen (device-to-device kopya):** 241.81 GB/s — teorik değerin %75.6'sı

Ölçüm koşulları: 256 MB tampon, `cudaMemcpy` D2D, 10 warm-up + 50 tekrar,
CUDA events ile zamanlama. Kod: `src/faz0/bandwidth_test.cu`

Not: Teorik tavan (320.06) DRAM'in ideal koşuldaki sayısı. Aradaki farkı
okuma-yazma geçişleri, refresh döngüleri ve bellek denetleyicisi verimi yer.
T4 70W'lık bir kart olduğu için güç/termal sınır da pay sahibi olabilir.

**Roofline kararı:** Grafikte iki eğik çatı çizilecek — teorik 320.06 (fiziğin
sınırı) ve ölçülen 241.81 (gerçekçi hedef). Kernel'ler ikisinin arasına
düştüğünde farkın ne kadarının koddan, ne kadarının donanımın doğasından
geldiği ayırt edilebilir.
