# Faz 0 — Gün 7: Stres Testleri (Tarama A ve B)

## Tarama A: Problem Boyutu Stres Testi
| N (Eleman) | Boyut (MB) | Sure (ms) | Bant Gen. (GB/s) |
|---|---|---|---|
| 10000 | 0.04 | 0.003 | 37.78 |
| 50000 | 0.19 | 0.005 | 126.40 |
| 100000 | 0.38 | 0.005 | 251.88 |
| 500000 | 1.91 | 0.013 | 478.85 |
| 1000000 | 3.81 | 0.049 | 246.83 |
| 5000000 | 19.07 | 0.229 | 262.11 |
| 10000000 | 38.15 | 0.454 | 264.03 |
| 50000000 | 190.73 | 2.259 | 265.60 |
| 100000000 | 381.47 | 4.635 | 258.91 |

**Analiz:**
* Küçük boyutlarda (10k-50k) hızın düşük olmasının nedeni, kernel başlatma (launch overhead) maliyetinin yüksek olması ve GPU'nun doldurulamamasıdır[cite: 2].
* 500.000 elemanda (1.91 MB) bant genişliğinin 478.85 GB/s ile T4'ün teorik bant genişliğini aşması, verinin tamamen GPU'nun L2 önbelleğine sığdığını ve DRAM (global bellek) hızını değil, önbellek hızını ölçtüğümüzü gösterir.
* 5 milyon eleman (19 MB) ve sonrasında değerler 260-265 GB/s bandında bir platoya oturuyor ve doyuma ulaşıyor[cite: 2].

---

## Tarama B: Block Boyutu Stres Testi
| Thread/Block | Sure (ms) | Bant Gen. (GB/s) |
|---|---|---|
| 32 | 2.689 | 149.76 |
| 64 | 1.533 | 262.60 |
| 128 | 1.565 | 257.36 |
| 256 | 1.564 | 257.48 |
| 512 | 1.564 | 257.43 |
| 1024 | 1.566 | 257.17 |

**Analiz:**
* Çok küçük bloklar (32) kullanıldığında SM (Streaming Multiprocessor) üzerindeki donanımsal blok sınırına takılıyoruz, bu da çok düşük occupancy (%50) değerlerine neden olarak bant genişliğini 149.76 GB/s'ye düşürüyor[cite: 2].
* Ortalarda (64 - 1024 arası) SM tam kapasiteyle (1024 thread) çalıştığı için performans tepe noktasına ulaşıyor ve stabil kalıyor[cite: 2].
* SAXPY kernel'i çok az kaynak tükettiği için uç noktadaki 1024 thread/block değerinde bile performans kaybı (register baskısı) yaşanmıyor.
