#include <cstdio>
#include <cuda_runtime.h>

int main() {
    size_t N = 256 * 1024 * 1024;   // 256 MB
    const int WARMUP = 10;
    const int N_ITER = 50;

    float *d_src, *d_dst;
    cudaMalloc(&d_src, N);
    cudaMalloc(&d_dst, N);
    cudaMemset(d_src, 1, N);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    // Warm-up: karti uyandir, olcme
    for (int i = 0; i < WARMUP; ++i)
        cudaMemcpy(d_dst, d_src, N, cudaMemcpyDeviceToDevice);
    cudaDeviceSynchronize();

    cudaEventRecord(start);
    for (int i = 0; i < N_ITER; ++i)
        cudaMemcpy(d_dst, d_src, N, cudaMemcpyDeviceToDevice);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms;
    cudaEventElapsedTime(&ms, start, stop);

    double seconds   = ms / 1000.0;
    double totalBytes = 2.0 * (double)N * N_ITER;   // okuma + yazma
    double gbps      = totalBytes / seconds / 1.0e9;

    printf("Toplam sure: %.3f ms (%d tekrar)\n", ms, N_ITER);
    printf("Kopya basina: %.3f ms\n", ms / N_ITER);
    printf("Efektif bant genisligi: %.2f GB/s\n", gbps);
    printf("Teorik tavanin (320.06) yuzdesi: %.1f%%\n", gbps / 320.06 * 100.0);

    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    cudaFree(d_src);
    cudaFree(d_dst);
    return 0;
}
