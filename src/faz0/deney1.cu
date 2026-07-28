
// ============================================================
// Faz 0 - Gun 3-4 - Deney 1: CPU saati (chrono) vs CUDA events
// Amac: Asenkron launch yuzunden CPU saatinin (sync'siz) neden
//   yaniltici oldugunu gostermek. Uc olcum: A=CPU sync'siz,
//   B=CPU sync'li, C=CUDA events. Sonuc ve yorum: notes/faz0-gun3-4-zamanlama.md
// ============================================================


#include <cstdio>
#include <cuda_runtime.h>
#include <chrono>          // CPU saati için
#include <iostream>

int main() {
    size_t N = 256 * 1024 * 1024;
    float *d_src, *d_dst;
    cudaMalloc(&d_src, N);
    cudaMalloc(&d_dst, N);
    cudaMemset(d_src, 1, N);

    // Isınma: ilk çağrının şişkinliği bu deneyi kirletmesin (Deney 2'de bunu inceleyeceksin;
    // burada sadece temiz sonuç için birkaç kez çağırıp sync et)
    for (int i = 0; i < 5; ++i)
        cudaMemcpy(d_dst, d_src, N, cudaMemcpyDeviceToDevice);
    cudaDeviceSynchronize();

    // ================= ÖLÇÜM A: CPU saati, SYNC YOK =================
    auto t0_a = std::chrono::steady_clock::now();
    cudaMemcpy(d_dst, d_src, N, cudaMemcpyDeviceToDevice);
    auto t1_a = std::chrono::steady_clock::now();
    auto fark_a = std::chrono::duration_cast<std::chrono::microseconds>(t1_a - t0_a);
    printf("A (sync yok): %ld us\n", fark_a.count());

    // ================= ÖLÇÜM B: CPU saati, SYNC VAR =================
    auto t0_b = std::chrono::steady_clock::now();
    cudaMemcpy(d_dst, d_src, N, cudaMemcpyDeviceToDevice);
    cudaDeviceSynchronize();   // <-- tek fark bu satır: CPU'yu GPU bitene kadar beklet
    auto t1_b = std::chrono::steady_clock::now();
    auto fark_b = std::chrono::duration_cast<std::chrono::microseconds>(t1_b - t0_b);
    printf("B (sync var): %ld us\n", fark_b.count());

    // ================= ÖLÇÜM C: CUDA events (altın standart) =================
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);
    cudaMemcpy(d_dst, d_src, N, cudaMemcpyDeviceToDevice);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float ms;
    cudaEventElapsedTime(&ms, start, stop);
    printf("C (events):   %.1f us\n", ms * 1000.0);   // ms -> us icin *1000
    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    cudaFree(d_src);
    cudaFree(d_dst);
    return 0;
}


//Sync yok: CPU işi kuyruğa atar, hemen devam eder. CPU, GPU'nun işi bitirip bitirmediğini bilmez, umursamaz — kendi yoluna gider.
//Sync var: CPU işi kuyruğa atar, sonra cudaDeviceSynchronize() ile durup bekler. GPU işi gerçekten bitirene kadar CPU orada takılı kalır, ondan sonra devam eder.

//A (CPU + sync yok) en kısa → CPU beklemiyor, sadece "işi kuyruğa attım" süresini görüyor, kopyalamanın kendisini değil.
//B (CPU + sync var) uzun → CPU bariyerde bekliyor, o yüzden gerçek kopyalama süresini yakalıyor.
//C (events) → bekleme/beklememe olayına takılmadan doğrudan GPU'nun gerçek süresini ölçüyor.
