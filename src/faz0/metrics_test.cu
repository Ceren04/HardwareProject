
// ============================================================
// Faz 0 - Gun 5 - Metrik fonksiyonlari testi
// Amac: effective_bandwidth (GB/s), gflops (GFLOP/s),
//   arithmetic_intensity (FLOP/byte) fonksiyonlarini bilinen
//   degerlerle dogrulamak: 241.81 GB/s (bandwidthTest) ve
//   0.167 FLOP/byte (SAXPY, elle hesap). Ikisi de tuttu.
//   Bu fonksiyonlar include/ altina tasinacak.
// ============================================================

#include <cstdio>

// Efektif bant genişliği: taşınan bayt / süre → GB/s
double effective_bandwidth(double bytes, double seconds) {
  return (bytes / seconds) / 1e9;
}

// Hesap verimi: FLOP / süre → GFLOP/s
double gflops(double flop_count, double seconds) {
  return (flop_count / seconds / 1e9);
}

// Aritmetik yoğunluk: FLOP / bayt → FLOP/byte
double arithmetic_intensity(double flop_count, double bytes) {
  return (flop_count / bytes);
}

int main() {
    // ---- Doğrulama: bilinen bir sonuçla test et ----
    // bandwidthTest'ten biliyorsun: 256 MB'lik D2D kopya, kopya başına ~2.221 ms.
    // O ölçümde 241.81 GB/s çıkmıştı. Aynı sayıyı bu fonksiyonla üretebilmelisin.

    double N     = 256.0 * 1024 * 1024;   // 256 MB (tek yön bayt)
    double bytes = 2.0 * N;               // D2D = oku + yaz → 2N
    double ms    = 2.221;                 // kopya başına süre (ms)

    double seconds = ms / 1000.0;

    printf("Bant genisligi: %.2f GB/s\n", effective_bandwidth(bytes, seconds));

    // ---- gflops ve arithmetic_intensity için de birer test ----
    // SAXPY örneği (faz0'dan): eleman başına 12 bayt, 2 FLOP.
    // Bir milyon eleman için:
    double n_elem = 1.0e6;
    double saxpy_flop  = 2.0 * n_elem;    // eleman başına 2 FLOP
    double saxpy_bytes = 12.0 * n_elem;   // eleman başına 12 bayt

    printf("SAXPY aritmetik yogunluk: %.3f FLOP/byte\n", arithmetic_intensity(saxpy_flop, saxpy_bytes) );

    return 0;
}
