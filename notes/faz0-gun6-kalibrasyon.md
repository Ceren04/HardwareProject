
## SAXPY (Memory-Bound) Ölçüm Sonuçları
* **Süre (kopya başına):** 1.520 ms
* **Efektif Bant Genişliği:** 264.95 GB/s
* **Aritmetik Yoğunluk:** 0.167 FLOP/byte
* **Pratik Tavana Oranı:** %109.6

**Yorum:** Aritmetik yoğunluk 0.167 FLOP/byte ile sırt noktasının (25.43) çok altında kaldı. Bu da kernelin tamamen "memory-bound" olduğunu doğruluyor. Elde edilen 264.95 GB/s, T4'ün teorik tavanının (320.06 GB/s) yaklaşık %82.7'sine denk geliyor ki bu da Faz 0 beklentileriyle (%70-90) mükemmel bir şekilde uyuşuyor.

## FMA (Compute-Bound) Ölçüm Sonuçları
* **Süre (kopya başına):** 0.509 ms
* **Performans:** 4123.40 GFLOP/s
* **Aritmetik Yoğunluk:** 500.0 FLOP/byte
* **Teorik Tepe Oranı:** %50.7

**Yorum:** Aritmetik yoğunluk 500.0 FLOP/byte ile sırt noktasının çok üzerinde yer alıyor. Kernel kesinlikle "compute-bound". %50.7'lik performans oranı ise basit bir döngüden beklenen %50+ hedefine tam olarak ulaşıldığını kanıtlıyor.
