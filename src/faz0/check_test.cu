
// ============================================================
// Faz 0 - Gun 5 - checkCudaErrors makro testi
// Amac: Her CUDA cagrisinin hata kodunu otomatik kontrol eden,
//   hata varsa dosya+satir+mesaj basip duran makroyu dogrulamak.
//   Test 1: basarili cagri (makro sessiz). Test 2: kasitli hata (yakalar, durur).
//   Bu makro include/ altina tasinacak, GEMM boyunca kullanilacak.
// ============================================================

#include <cstdio>
#include <cstdlib>          // exit() için
#include <cuda_runtime.h>
#include <iostream>

// ============================================================
// checkCudaErrors makrosu
// ============================================================
#define checkCudaErrors(call)                                        \
    do {                                                             \
        cudaError_t err = (call);   /* çağrıyı BİR kez çalıştır */   \
        if (err != cudaSuccess) {                                    \
        printf("CUDA hata: %s:%d - %s\n", __FILE__, __LINE__, cudaGetErrorString(err)); \
              exit(EXIT_FAILURE);                                    \
        }                                                            \
    } while (0)


int main() {
    size_t N = 256 * 1024 * 1024;
    float *d_src;

    // ---- TEST 1: başarılı çağrı — makro SESSİZ kalmalı ----
    checkCudaErrors( cudaMalloc(&d_src, N) );
    printf("Test 1 gecti: cudaMalloc basarili, makro sessiz kaldi.\n");

    // ---- TEST 2: kasıtlı HATALI çağrı — makro YAKALAMALI ----
    // GPU limitlerini kesinlikle aşacak absürt büyüklükte bellek boyutu (1 Terabayt)
    size_t cok_buyuk_bir_sayi = 1ULL << 40; 
    float *d_err = nullptr;

    // Satır senin makron ile sarıldı, program burada hata verip duracak
    checkCudaErrors( cudaMalloc(&d_err, cok_buyuk_bir_sayi) );

    // Makro yukarıda programı durduracağı için bu satırlara asla ulaşılamayacak
    cudaFree(d_src);
    return 0;
}
