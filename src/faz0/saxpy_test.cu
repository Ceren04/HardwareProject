#include <cstdio>
#include "include/cuda_check.cuh"
#include "include/timing.cuh"
#include "include/metrics.cuh"

// SAXPY Kernel'i
__global__ void saxpy_kernel(int n, float a, float *x, float *y) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n){
        y[i] = a * x[i] + y[i];
    }
}

int main() {
    int N = 1 << 25; // Yaklaşık 33.5 milyon eleman 
    size_t size = N * sizeof(float);
    
    float *d_x, *d_y;
    checkCudaErrors(cudaMalloc(&d_x, size));
    checkCudaErrors(cudaMalloc(&d_y, size));
    
    // Bellekleri 0 ile ilklendiriyoruz
    checkCudaErrors(cudaMemset(d_x, 0, size));
    checkCudaErrors(cudaMemset(d_y, 0, size));
    
    float a = 2.0f;
    int threadsPerBlock = 256;
    
    // Tavana yuvarlama ile grid boyutu hesabı
    int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;

    // Lambda ile zamanlama terazisine kernel'i veriyoruz
    auto kernel_call = [&]() {
        saxpy_kernel<<<blocksPerGrid, threadsPerBlock>>>(N, a, d_x, d_y);
    };

    // 50 tekrar, 10 warm-up
    float ms = repeat(kernel_call, 50, 10); 
    double seconds_per_iter = (ms / 50.0) / 1000.0;

    // Eleman başına 12 bayt bellek trafiği
    double total_bytes = 12.0 * N; 
    
    // Eleman başına 2 FLOP matematiksel işlem
    double total_flops = 2.0 * N; 

    double gbps = effective_bandwidth(total_bytes, seconds_per_iter);
    double ai = arithmetic_intensity(total_flops, total_bytes);

    printf("--- SAXPY SONUCLARI ---\n");
    printf("Sure (kopya basina): %.3f ms\n", ms / 50.0);
    printf("Efektif Bant Genisligi: %.2f GB/s\n", gbps);
    printf("Aritmetik Yogunluk: %.3f FLOP/byte\n", ai);
    printf("Pratik Tavana (241.81 GB/s) Orani: %%%.1f\n", (gbps / 241.81) * 100.0);

    checkCudaErrors(cudaFree(d_x));
    checkCudaErrors(cudaFree(d_y));
    return 0;
}
