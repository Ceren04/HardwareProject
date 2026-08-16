
# GEMM Hafta 2 — Naif GEMM (Baseline) + cuBLAS Tavanı

## Amaç
Tırmanışın referans noktalarını kurmak: en basit doğru kernel (naif) ve
ulaşılacak tavan (cuBLAS). Tüm tırmanış bu ikisinin arasında geçecek.

## Naif kernel
Her thread C'nin bir elemanını hesaplar: C[row][col] = Σ_k A[row][k]·B[k][col].
2B grid/block ile indekslenir (satır→y, sütun→x). Row-major bellek:
A[row][k] → A[row*K+k], B[k][col] → B[k*N+col], C[row][col] → C[row*N+col].

## Doğruluk
İlk test: A=B=1.0f → her C elemanı tam K (1024) çıkmalı → hC[0]=1024.0 ✓
Asıl test: RASTGELE veri ile naif çıktısı cuBLAS ile karşılaştırıldı.
Neden rastgele: 1.0f simetriktir, column-major hatasını gizler. Rastgele veri
transpoze hatasını ortaya çıkarır. Göreli hata eşiği 1e-2 (fp32'de birebir tutmaz).
Sonuç: GECTI → column-major doğru kuruldu, kernel doğru.

## cuBLAS (column-major tuzağı)
cuBLAS column-major bekler, benim matrislerim row-major. Row-major bir matrisi
column-major okuyan onun transpozunu görür. Çözüm (kolay yol): cuBLAS'a A ve B'yi
ters sırayla vererek column-major'da B*A hesaplatmak → sonuç benim row-major
C = A*B ile uyuşuyor. Özdeşlik: Cᵀ = Bᵀ·Aᵀ.

## Ölçümler (M=N=K=1024, T4)
| Kernel | Süre | GFLOP/s | Tepe % | cuBLAS'a oran |
|---|---|---|---|---|
| Naif   | 5.569 ms | 385.6  | %4.7  | %8.3 |
| cuBLAS | 0.465 ms | 4621.9 | %56.8 | %100 |

## Roofline yorumu
- **Naif:** AI ≈ 0.25 FLOP/byte (thread başına A'dan+B'den 8 bayt oku, 2 FLOP).
  Sırt noktasının (25.4) çok solunda → MEMORY-BOUND. Eğik çatının altında,
  sol-alt bölgede. A'nın her elemanı N=1024 kez global bellekten okunuyor,
  veri yeniden kullanımı yok → bant genişliği duvarı.
- **cuBLAS:** AI ≈ 170 (GEMM'in ideal AI'si: 2MNK / (MK+KN+MN)·4). Sırt noktasının
  sağında → COMPUTE-BOUND. Yatay çatının hemen altında (tepenin %57'si; hiçbir
  kernel %100'e ulaşmaz).

## Asıl ders
Naif→cuBLAS mesafesi iki eksende: SAĞA (AI 0.25→170, veri yeniden kullanımı) VE
YUKARI (385→4622 GFLOP/s). Yukarı çıkmak için önce sağa gitmek şart — memory-bound
bölgede kaldıkça eğik çatı tavana ulaşmayı engeller. Tiling'in (Hafta 4) neden en
önemli adım olduğu bu: seni sağa taşıyan ilk hamle.

## Bitti ölçütü ✓
Naif doğruluğu geçiyor · Naif+cuBLAS roofline'da konumlu · "naif neden memory-bound"
açıklandı · check_correctness (göreli hata) fonksiyonu hazır, her hafta çağrılacak.
