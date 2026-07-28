
// ============================================================
// Faz 0 - Gun 3-4 - Deney 2b: warm-up=10 (isitmali olcum)
// Amac: Deney 2a (warmup=0) ile karsilastirilarak warm-up'in
//   etkisini olcmek. Sonuc ve yorum: notes/faz0-gun3-4-zamanlama.md
// ============================================================


#include <cstdio>
#include <cuda_runtime.h>

template <typename F>
float repeat(F is, int N_ITER, int WARMUP) {   
    cudaEvent_t start, stop;             
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    // Warm-up: karti uyandir, olcme
    for (int i = 0; i < WARMUP; ++i)
        is();
  
    cudaDeviceSynchronize();
    cudaEventRecord(start);
    for (int i = 0; i < N_ITER; ++i)
        is();
       
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float ms;
    cudaEventElapsedTime(&ms, start, stop);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    return ms;      
}

int main() {
    size_t N = 256 * 1024 * 1024;
    float *d_src, *d_dst;
    cudaMalloc(&d_src, N);
    cudaMalloc(&d_dst, N);
    cudaMemset(d_src, 1, N);

    // DİKKAT: burada BAŞKA hiçbir CUDA işi çalıştırma (cudaMalloc/memset zaten
    //   context'i biraz ısıtır ama memcpy'yi ilk kez repeat içinde çalıştıracağız).
    //   Amaç: repeat'e girmeden önce hiç memcpy yapılmamış olması.

    // >>> SEN: repeat'i çağır — memcpy lambda'sı, N_ITER = 1, WARMUP = 10
    //     Dönen ms'i yakala.
    float ms = repeat( [&](){cudaMemcpy(d_dst, d_src, N, cudaMemcpyDeviceToDevice);}, 1, 10 );

    printf("warmup=10, iter=1: %.4f ms\n", ms);

    cudaFree(d_src);
    cudaFree(d_dst);
    return 0;
}
