#include <cstdio>
#include "include/cuda_check.cuh"
#include "include/timing.cuh"
#include "include/metrics.cuh"

// FMA (Fused Multiply-Add) Kernel'i
__global__ void fma_kernel(int n, int iters, float *out) {
    // thread.x yerine threadIdx.x kullanıldı
    int i = blockIdx.x * blockDim.x + threadIdx.x; 
    
    if (i < n) {
        float val = 1.01f;
        for (int j = 0; j < iters; j++) {
            val = val * 1.0001f + 0.0001f;
        }
        out[i] = val;
    }
}

int main() {
    int N = 1 << 20; 
    int ITERS = 1000; 
    size_t size = N * sizeof(float);
    
    float *d_out;
    checkCudaErrors(cudaMalloc(&d_out, size));
    
    int threadsPerBlock = 256;
    
    // Tavana yuvarlama ile grid boyutu hesabı
    int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;

    // Lambda ile zamanlama terazisine kernel'i veriyoruz
    auto kernel_call = [&]() {
        fma_kernel<<<blocksPerGrid, threadsPerBlock>>>(N, ITERS, d_out);
    };

    // 50 tekrar, 10 warm-up
    float ms = repeat(kernel_call, 50, 10);
    double seconds_per_iter = (ms / 50.0) / 1000.0;

    // N thread * 1000 iterasyon * 2 FLOP
    double total_flops = 2.0 * N * ITERS; 
    
    // N thread * 4 bayt (sadece yazma)
    double total_bytes = 4.0 * N; 

    double gflops_val = gflops(total_flops, seconds_per_iter);
    double ai = arithmetic_intensity(total_flops, total_bytes);

    printf("--- FMA SONUCLARI ---\n");
    printf("Sure (kopya basina): %.3f ms\n", ms / 50.0);
    printf("Performans: %.2f GFLOP/s\n", gflops_val);
    printf("Aritmetik Yogunluk: %.1f FLOP/byte\n", ai);
    printf("Teorik Tepe (8140 GFLOP/s) Orani: %%%.1f\n", (gflops_val / 8140.0) * 100.0);

    checkCudaErrors(cudaFree(d_out));
    return 0;
}
