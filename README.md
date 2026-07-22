# GEMM Tırmanışı + Roofline

CUDA öğrenme projesi. Ölçüm laboratuvarı (Faz 0) → naif GEMM'den cuBLAS'a optimizasyon tırmanışı.
Donanım: NVIDIA Tesla T4 (Turing, sm_75), Google Colab.

## Klasörler
- `src/faz0/` — ölçüm altyapısı ve kalibrasyon kernel'leri
- `src/gemm/` — GEMM tırmanışının kernel'leri
- `include/` — ortak başlıklar (zamanlama, metrikler, hata makrosu)
- `results/` — ölçüm sonuçları (CSV)
- `notes/` — haftalık gözlemler ve "neden" açıklamaları
- `plots/` — roofline grafikleri
