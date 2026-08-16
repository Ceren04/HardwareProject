#include <cstdio>
#include <cstdlib>
#include "include/cuda_check.cuh"
#include "include/timing.cuh"
#include "include/metrics.cuh"

// ============================================================
// Naif GEMM kernel: C = A * B
// A: MxK, B: KxN, C: MxN  (hepsi row-major, tek boyutlu dizi)
// Her thread C'nin BİR elemanını hesaplar.
// ============================================================
__global__ void naive_gemm(const float* A, const float* B, float* C,
                           int M, int N, int K) {

    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;

    if (row < M && col < N) {
        float sum = 0.0f;
        for (int k = 0; k < K; ++k) {
            sum += A[row*K + k] * B[k*N + col];
        }
       C[row*N + col] = sum;
    }
}

int main() {
    int M = 1024, N = 1024, K = 1024;
    size_t bytesA = (size_t)M * K * sizeof(float);
    size_t bytesB = (size_t)K * N * sizeof(float);
    size_t bytesC = (size_t)M * N * sizeof(float);

    float *hA = (float*)malloc(bytesA);
    float *hB = (float*)malloc(bytesB);
    float *hC = (float*)malloc(bytesC);
    for (int i = 0; i < M*K; ++i) hA[i] = 1.0f;
    for (int i = 0; i < K*N; ++i) hB[i] = 1.0f;

    // --- Device belleği ayır + kopyala ---
    float *dA, *dB, *dC;
    checkCudaErrors( cudaMalloc(&dA, bytesA) );
    checkCudaErrors( cudaMalloc(&dB, bytesB) );
    checkCudaErrors( cudaMalloc(&dC, bytesC) );
    checkCudaErrors( cudaMemcpy(dA, hA, bytesA, cudaMemcpyHostToDevice) );
    checkCudaErrors( cudaMemcpy(dB, hB, bytesB, cudaMemcpyHostToDevice) );

    // --- Launch konfigürasyonu ---
    dim3 block(16, 16);
    dim3 grid( (N + block.x - 1)/block.x,
           (M + block.y - 1)/block.y );

    // --- Ölç (terazi ile) ---
    float ms = repeat( [&](){ naive_gemm<<<grid, block>>>(dA, dB, dC, M, N, K); }, 20, 5 );

    checkCudaErrors( cudaGetLastError() );
    checkCudaErrors( cudaDeviceSynchronize() );

    // --- Sonucu geri al + doğrula ---
    checkCudaErrors( cudaMemcpy(hC, dC, bytesC, cudaMemcpyDeviceToHost) );
    printf("Dogruluk: hC[0] = %.1f (beklenen: %d)\n", hC[0], K);

    // --- Metrikler ---
    double seconds = (ms / 20.0) / 1000.0;   // ortalama süre, ms->s  (DİKKAT: repeat toplam veriyor, /20)
    double flop = 2.0 * M * N * K;           // GEMM FLOP formülü
    printf("Naif GEMM: %.3f ms/cagri, %.1f GFLOP/s\n", ms/20, gflops(flop, seconds));

    free(hA); free(hB); free(hC);
    cudaFree(dA); cudaFree(dB); cudaFree(dC);
    return 0;
}
