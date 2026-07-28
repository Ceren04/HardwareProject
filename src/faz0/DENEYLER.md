# Faz 0 - Gun 3-4 Deney Dosyalari

Bu klasordeki deney (.cu) dosyalari, zamanlama terazisinin (repeat)
davranisini dogrulamak icin yapilan tek seferlik olcumlerdir.
Detayli sonuc ve yorumlar: `notes/faz0-gun3-4-zamanlama.md`

| Dosya | Deney | Amac |
|---|---|---|
| deney1.cu  | CPU saati vs CUDA events | Asenkron launch'in CPU olcumunu neden yaniltigini gostermek (A sync'siz, B sync'li, C events) |
| deney2a.cu | warm-up = 0  | Isitmasiz olcum (ilk-cagri sisiskinligi dahil) |
| deney2b.cu | warm-up = 10 | Isitmali olcum; 2a ile karsilastirilir |

Not: deney2a ve deney2b AYRI programlar cunku her `./program` taze/soguk
bir surec baslatir; soguk baslangic etkisini gormek icin bu gerekli.

## Gun 5 dosyalari
| Dosya | Ne | Amac |
|---|---|---|
| check_test.cu   | checkCudaErrors makro testi | Sessiz hata tuzagini cozen makronun dogrulanmasi |
| metrics_test.cu | Metrik fonksiyon testi | bandwidth/gflops/arithmetic_intensity'nin bilinen degerlerle kalibrasyonu |
