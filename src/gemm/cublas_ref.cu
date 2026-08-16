#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <cublas_v2.h>
#include "include/cuda_check.cuh"
#include "include/timing.cuh"
#include "include/metrics.cuh"

// ============================================================
// Naif GEMM + cuBLAS referansı + doğruluk karşılaştırması
// ============================================================


__global__ void naive_gemm(const float* A, const float* B, float* C, int M, int N, int K) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    if (row < M && col < N) {
        float sum = 0.0f;
        for (int k = 0; k < K; ++k) sum += A[row*K + k] * B[k*N + col];
        C[row*N + col] = sum;
    }
}

bool check_correctness(const float* mine, const float* reference, int size, float tol) {
    for (int i = 0; i < size; ++i) {
        float ref_val = reference[i];
        float diff = fabsf(mine[i] - ref_val);
        float rel = diff / (fabsf(ref_val) + 1e-6f);
        if (rel > tol) {
            printf("Hata @ İndeks %d: mine=%f, ref=%f (rel=%.5f)\n", i, mine[i], ref_val, rel);
            return false;
        }
    }
    return true;
}

int main() {
    int M = 1024, N = 1024, K = 1024;
    size_t bytesA = (size_t)M*K*sizeof(float);
    size_t bytesB = (size_t)K*N*sizeof(float);
    size_t bytesC = (size_t)M*N*sizeof(float);

    float *hA=(float*)malloc(bytesA), *hB=(float*)malloc(bytesB);
    float *hC_naive=(float*)malloc(bytesC), *hC_cublas=(float*)malloc(bytesC);
    for (int i=0; i<M*K; ++i) hA[i] = (float)rand()/RAND_MAX;
    for (int i=0; i<K*N; ++i) hB[i] = (float)rand()/RAND_MAX;

    float *dA, *dB, *dC;
    checkCudaErrors( cudaMalloc(&dA, bytesA) );
    checkCudaErrors( cudaMalloc(&dB, bytesB) );
    checkCudaErrors( cudaMalloc(&dC, bytesC) );
    checkCudaErrors( cudaMemcpy(dA, hA, bytesA, cudaMemcpyHostToDevice) );
    checkCudaErrors( cudaMemcpy(dB, hB, bytesB, cudaMemcpyHostToDevice) );

    // ===== 1) NAİF KERNEL =====
    dim3 block(16,16);
    dim3 grid( (N+block.x-1)/block.x, (M+block.y-1)/block.y );
    float ms_naive = repeat( [&](){ naive_gemm<<<grid,block>>>(dA,dB,dC,M,N,K); }, 20, 5 );
    checkCudaErrors( cudaGetLastError() );
    checkCudaErrors( cudaDeviceSynchronize() );
    checkCudaErrors( cudaMemcpy(hC_naive, dC, bytesC, cudaMemcpyDeviceToHost) );

    // ===== 2) cuBLAS REFERANSI =====
    cublasHandle_t handle;
    cublasCreate(&handle);
    float alpha = 1.0f, beta = 0.0f;

    float ms_cublas = repeat( [&](){ 
        cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, 
                    N, M, K, 
                    &alpha, dB, N, dA, K, &beta, dC, N); 
    }, 20, 5 );
    
    checkCudaErrors( cudaDeviceSynchronize() );
    checkCudaErrors( cudaMemcpy(hC_cublas, dC, bytesC, cudaMemcpyDeviceToHost) );

    // ===== 3) DOĞRULUK =====
    bool ok = check_correctness(hC_naive, hC_cublas, M*N, 1e-2f);
    printf("Dogruluk (naif vs cuBLAS): %s\n", ok ? "GECTI" : "KALDI");

    // ===== 4) METRİKLER =====
    double flop = 2.0*M*N*K;
    double s_naive = (ms_naive /20.0)/1000.0;
    double s_cublas = (ms_cublas/20.0)/1000.0;
    printf("Naif  : %.3f ms, %.1f GFLOP/s (tepe % .1f%%)\n", ms_naive/20, gflops(flop,s_naive), gflops(flop,s_naive)/8140*100);
    printf("cuBLAS: %.3f ms, %.1f GFLOP/s (tepe % .1f%%)\n", ms_cublas/20, gflops(flop,s_cublas), gflops(flop,s_cublas)/8140*100);
    printf("Naif, cuBLAS in %%%.1f i kadar\n", gflops(flop,s_naive)/gflops(flop,s_cublas)*100);

    cublasDestroy(handle);
    free(hA); free(hB); free(hC_naive); free(hC_cublas);
    cudaFree(dA); cudaFree(dB); cudaFree(dC);
    return 0;
}
