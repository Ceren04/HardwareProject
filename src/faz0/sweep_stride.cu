#include <cstdio>
#include <vector>
#include "include/cuda_check.cuh"
#include "include/timing.cuh"
#include "include/metrics.cuh"

__global__ void stride_kernel(int n, int stride, float a, float *x, float *y) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    
    // TODO: 1. Bellekte erişeceğimiz gerçek indeksi (idx) hesapla
    // İpucu: Thread indeksi (i) ile stride değerini çarp
    int idx = i * stride; 

    // Thread sayımız n'den küçükse işlemi yap
    if (i < n) {
        // TODO: 2. İşlemi x[idx] ve y[idx] üzerinden yap
        y[idx] = a * x[idx] + y[idx];
    }
}

int main() {
    printf("--- TARAMA C: ERISIM DESENI (STRIDE) STRES TESTI ---\n");
    printf("%-15s %-15s %-15s\n", "Stride", "Sure (ms)", "Efektif Bant Gen. (GB/s)");
    printf("----------------------------------------------------\n");

    // İş yapacak thread sayısını sabit tutuyoruz (Örn: ~1 milyon)
    int N = 1 << 20; 
    
    // Test edeceğimiz maksimum stride değeri
    int MAX_STRIDE = 32;
    
    // Bellek sınırını aşmamak için dizileri N * MAX_STRIDE büyüklüğünde ayırıyoruz
    size_t total_elements = N * MAX_STRIDE;
    size_t size = total_elements * sizeof(float);
    float a = 2.0f;
    
    float *d_x, *d_y;
    checkCudaErrors(cudaMalloc(&d_x, size));
    checkCudaErrors(cudaMalloc(&d_y, size));
    checkCudaErrors(cudaMemset(d_x, 0, size));
    checkCudaErrors(cudaMemset(d_y, 0, size));

    // TODO: 3. Test edilecek stride değerlerini bir vektöre yaz (1, 2, 4, 8, 16, 32)
    std::vector<int> strides = {1, 2, 4, 8, 16, 32};
    
    int threadsPerBlock = 256;
    int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;

    for (int stride : strides) {
        
        auto kernel_call = [&]() {
            // TODO: 4. stride_kernel'i blocksPerGrid ve threadsPerBlock ile çağır. 
            // Argümanlar: N, stride, a, d_x, d_y
            stride_kernel<<<blocksPerGrid, threadsPerBlock>>>(N, stride, a, d_x, d_y);
        };

        // Zamanı ölç
        float ms = repeat(kernel_call, 50, 10);
        double seconds_per_iter = (ms / 50.0) / 1000.0;
        
        // TODO: 5. Efektif bant genişliğini hesapla. 
        // DİKKAT: Yapılan "faydalı" iş hep sabit! Yani taşınan bayt sayısı stride'dan bağımsız olarak (12.0 * N).
        // N adet element okuma (x), N adet element okuma (y), N adet element yazma (y) = 3 * N * 4 byte = 12.0 * N
        double total_useful_bytes = 12.0 * N; 
        double gbps = effective_bandwidth(total_useful_bytes, seconds_per_iter);
        
        printf("%-15d %-15.3f %-15.2f\n", stride, ms / 50.0, gbps);
    }
    
    checkCudaErrors(cudaFree(d_x));
    checkCudaErrors(cudaFree(d_y));
    
    return 0;
}
