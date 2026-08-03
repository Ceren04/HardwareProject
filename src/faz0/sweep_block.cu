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
    printf("--- TARAMA B: BLOCK BOYUTU STRES TESTI ---\n");
    printf("%-15s %-15s %-15s\n", "Thread/Block", "Sure (ms)", "Bant Gen. (GB/s)");
    printf("------------------------------------------------\n");

    // N'i platoya ulaştığımız, GPU'yu doyuran sabit bir boyuta alıyoruz
    int N = 1 << 25; // Yaklaşık 33.5 milyon eleman
    size_t size = N * sizeof(float);
    float a = 2.0f;
    
    // Bellek tahsislerini döngü dışında BİR KERE yapıyoruz (Boyut sabit)
    float *d_x, *d_y;
    checkCudaErrors(cudaMalloc(&d_x, size));
    checkCudaErrors(cudaMalloc(&d_y, size));
    checkCudaErrors(cudaMemset(d_x, 0, size));
    checkCudaErrors(cudaMemset(d_y, 0, size));

    // TODO: 1. Test edilecek block boyutlarını (threadsPerBlock) bir std::vector içine yaz.
    // İstenen değerler: 32, 64, 128, 256, 512, 1024[cite: 2].
    std::vector<int> block_sizes = {
      32, 64, 128, 256, 512, 1024
    };
    
    for (int threadsPerBlock : block_sizes) {
        
        // TODO: 2. O anki threadsPerBlock için blocksPerGrid hesapla (Tavana yuvarlama formülü)
        int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;
        
        auto kernel_call = [&]() {
            saxpy_kernel<<<blocksPerGrid, threadsPerBlock>>>(N, a, d_x, d_y);
        };

        // TODO: 3. repeat fonksiyonu ile 50 tekrar, 10 warm-up ölçümü yap
        float ms = repeat(kernel_call, 50, 10);
        double seconds_per_iter = (ms / 50.0) / 1000.0;
        
        // TODO: 4. Toplam bayt sayısını hesapla ve effective_bandwidth'i bul
        double total_bytes = 12.0 * N;
        double gbps = effective_bandwidth(total_bytes, seconds_per_iter);
        
        printf("%-15d %-15.3f %-15.2f\n", threadsPerBlock, ms / 50.0, gbps);
    }
    
    // İşlem bittikten sonra belleği serbest bırak
    checkCudaErrors(cudaFree(d_x));
    checkCudaErrors(cudaFree(d_y));
    
    return 0;
}
