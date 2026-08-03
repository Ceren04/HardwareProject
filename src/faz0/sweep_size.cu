#include <cstdio>
#include <vector>
#include "include/cuda_check.cuh"
#include "include/timing.cuh"
#include "include/metrics.cuh"

// Standart SAXPY Kernel
__global__ void saxpy_kernel(int n, float a, float *x, float *y) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        y[i] = a * x[i] + y[i];
    }
}

int main() {
    printf("--- TARAMA A: PROBLEM BOYUTU STRES TESTI ---\n");
    printf("%-15s %-15s %-15s %-15s\n", "N (Eleman)", "Boyut (MB)", "Sure (ms)", "Bant Gen. (GB/s)");
    printf("----------------------------------------------------------------\n");

    float a = 2.0f;
    int threadsPerBlock = 256;

    // Test edilecek farklı problem boyutları (eleman sayıları)
    std::vector<int> sizes = {10000, 50000, 100000, 500000, 1000000, 5000000, 10000000, 50000000, 100000000};
    
    // Test edilecek her bir N boyutu için işlemleri baştan sona tekrarlayan ANA DÖNGÜ
    for (int N : sizes) {
        
        // 1. O anki N değeri için bayt cinsinden bellek boyutunu (size) hesapla
        size_t size = N * sizeof(float);
        
        // 2. Bellekleri GPU'da tahsis et ve 0 ile ilklendir
        float *d_x, *d_y;
        checkCudaErrors(cudaMalloc(&d_x, size));
        checkCudaErrors(cudaMalloc(&d_y, size));
        
        checkCudaErrors(cudaMemset(d_x, 0, size));
        checkCudaErrors(cudaMemset(d_y, 0, size));
        
        // 3. O anki N değeri için gerekli Grid boyutunu (blocksPerGrid) hesapla
        int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;

        // 4. Kernel çağrısını lambda içine al
        auto kernel_call = [&]() {
            saxpy_kernel<<<blocksPerGrid, threadsPerBlock>>>(N, a, d_x, d_y);
        };

        // 5. Zaman ölçümü yap
        float ms = repeat(kernel_call, 50, 10); 
        double seconds_per_iter = (ms / 50.0) / 1000.0;
        
        // 6. Efektif bant genişliğini (GB/s) hesapla
        double total_bytes = 12.0 * N; 
        double gbps = effective_bandwidth(total_bytes, seconds_per_iter);
        
        // 7. Elde edilen değerleri MB'a çevirip ekrana yazdır
        double size_mb = (double)size / (1024.0 * 1024.0);
        printf("%-15d %-15.2f %-15.3f %-15.2f\n", N, size_mb, ms / 50.0, gbps);

        // 8. O anki iterasyonun işi bittiğinde tahsis edilen belleği mutlaka serbest bırak (Memory Leak önlemi)
        checkCudaErrors(cudaFree(d_x));
        checkCudaErrors(cudaFree(d_y));
        
    } // Döngü sonu: Bir sonraki N değeri için her şey baştan başlayacak
    
    return 0;
}
