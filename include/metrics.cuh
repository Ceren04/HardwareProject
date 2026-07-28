#pragma once

// Metrik fonksiyonları. Bunlar sıradan fonksiyon (makro/template değil),
// o yüzden header'a konunca 'inline' gerekir — aksi halde bu header birden
// fazla .cu dosyasına include edilirse linker "çift tanım" hatası verir.

// Efektif bant genişliği: taşınan bayt / süre → GB/s
inline double effective_bandwidth(double bytes, double seconds) {
  return (bytes / seconds) / 1e9;
}

// Hesap verimi: FLOP / süre → GFLOP/s
inline double gflops(double flop_count, double seconds) {
  return (flop_count / seconds / 1e9);
}

// Aritmetik yoğunluk: FLOP / bayt → FLOP/byte
inline double arithmetic_intensity(double flop_count, double bytes) {
  return (flop_count / bytes);
}
