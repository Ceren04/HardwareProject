
# GEMM Hafta 3 — Global Memory Coalescing

## Amaç
Tek satır hesap değiştirmeden, sadece bellek erişim desenini düzelterek
bant genişliği kullanımının performansa etkisini ölçmek.

## Kavram
Bir warp (32 ardışık thread) belleğe eriştiğinde, ardışık adreslere gidiyorsa
donanım bunları az sayıda büyük işlemde birleştirir (coalesced, verimli).
Dağınık/stride'lı adreslere gidiyorsa her thread ayrı işlem gerektirir
(uncoalesced, israf). Erişim desenini thread eşlemesi (row/col'un threadIdx'e
bağlanışı) belirler.

## Deney: coalesced vs uncoalesced
Aynı GEMM kernel'i iki eşlemeyle:
- COALESCED:   col = threadIdx.x → ardışık thread → ardışık sütun
- UNCOALESCED: row = threadIdx.x → ardışık thread → ardışık satır (TERS)

Ters eşlemede C[row*N+col] ve A[row*K+k] erişimleri stride-N (1024) olur → felaket.
Kernel'in geri kalanı (hesap, döngü) birebir aynı → tek değişken: eşleme.

## Ölçüm (M=N=K=1024, A=B=1.0f, T4)
| Versiyon | Doğruluk | Süre | GFLOP/s | Tepe % |
|---|---|---|---|---|
| Coalesced   | OK | 7.695 ms  | 279.1 | %3.4 |
| Uncoalesced | OK | 18.078 ms | 118.8 | %1.5 |

**Coalesced, uncoalesced'in 2.3 KATI hızlı.**

Not: İkisi de "OK" — uncoalesced YANLIŞ değil, sadece YAVAŞ. Aynı doğru sonucu
(C=1024) hesaplıyor, belleği kötü kullanıyor.

## Neden "sadece" 2.3 kat? (stride 1024 için beklenenden az)
faz0 stride taramasında stride 32 neredeyse felaketti; burada stride 1024 ama
darbe daha yumuşak. İki sebep:
1. **Broadcast:** Uncoalesced versiyonda B[k*N+col] (col=threadIdx.y sabit) warp
   içinde aynı adres → broadcast, hâlâ verimli. Üç erişimden biri iyi kalıyor.
2. **L2 cache:** Stride'lı erişimde çekilen 32-baytlık bloğun "çöpe atılan"
   komşu elemanları L2'ye girer, sonraki warp'lar onları cache'ten bulur.
Ders: coalescing önemli ama tek belirleyici değil — cache ve broadcast darbeyi
yumuşatır. Gerçek dünyada darbeler nadiren "saf" olur.

## Roofline yorumu
İki nokta AYNI x'te (AI ≈ 0.25), sadece y'de ayrık:
- Coalesced üstte (279), uncoalesced altta (119), ikisi de eğik çatının altında.
- AI değişmedi çünkü ne FLOP ne mantıksal bayt değişti — sadece bant genişliği
  KULLANIMI değişti. O yüzden nokta YUKARI kaydı, SAĞA değil. (Hipotez tuttu.)
- İkisi de sırt noktasının (25.4) çok solunda → hâlâ derin memory-bound.
  Coalescing seni memory-bound bölgeden ÇIKARMADI, o bölge içinde yükseltti.

## Özel bulgu: naif zaten coalesced'di
Hafta 2 naif kernel'i col=threadIdx.x eşlemesiyle yazılmıştı → zaten coalesced.
Yani baseline'ım en baştan doğru taraftaydı; Boehm'ün büyük coalescing sıçraması
bende yok çünkü hiç uncoalesced olmadım. Bu deney bunu KANITLADI (coalesced
versiyon = naif ile aynı mertebede).

## Tırmanış içgörüsü
Şu ana kadar hep aynı dikey çizgide (AI=0.25) oynadım — memory-bound bölgede.
cuBLAS'a (AI≈170, sağ-üst) ulaşmanın tek yolu bu çizgiyi terk edip SAĞA kaymak:
veriyi global bellekten bir kez okuyup shared memory'de defalarca kullanmak.
Coalescing bunu yapamaz. Hafta 4 (tiling) noktayı ilk kez sağa taşıyacak.

## Bitti ölçütü ✓
Coalescing etkisi ölçüldü (2.3x) · "neden yukarı, sağa değil" açıklandı ·
AI'nin değişmediği gösterildi (aynı x) · baseline'ın zaten coalesced olduğu kanıtlandı.
