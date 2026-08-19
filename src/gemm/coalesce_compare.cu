#include <cstdio>
#include <cstdlib>
#include <cmath>
#include "include/cuda_check.cuh"
#include "include/timing.cuh"
#include "include/metrics.cuh"

// ============================================================
// COALESCED vs UNCOALESCED karşılaştırması
// Aynı hesap, sadece thread eşlemesi farklı → erişim deseni farklı.
// ============================================================

// --- İYİ versiyon: col = threadIdx.x (ardışık thread → ardışık sütun → coalesced) ---
__global__ void gemm_coalesced(const float* A, const float* B, float* C,
                               int M, int N, int K) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;   // sütun -> x
    int row = blockIdx.y * blockDim.y + threadIdx.y;   // satır -> y
    if (row < M && col < N) {
        float sum = 0.0f;
        for (int k = 0; k < K; ++k)
            sum += A[row*K + k] * B[k*N + col];
        C[row*N + col] = sum;
    }
}

// --- BOZUK versiyon: TERS eşleme ---
__global__ void gemm_uncoalesced(const float* A, const float* B, float* C,
                                 int M, int N, int K) {

    int row = blockIdx.x * blockDim.x + threadIdx.x;
    int col = blockIdx.y * blockDim.y + threadIdx.y;
    if (row < M && col < N) {
        float sum = 0.0f;
        for (int k = 0; k < K; ++k)
            sum += A[row*K + k] * B[k*N + col];
        C[row*N + col] = sum;
    }
}

// Basit doğruluk: A=B=1 → her C elemanı = K
bool check(const float* C, int size, float expected) {
    for (int i = 0; i < size; ++i)
        if (fabs(C[i] - expected) > 1e-2f) {
            printf("HATA: C[%d]=%.2f (beklenen %.2f)\n", i, C[i], expected);
            return false;
        }
    return true;
}

int main() {
    int M=1024, N=1024, K=1024;
    size_t bytes = (size_t)M*N*sizeof(float);  // hepsi kare, aynı boyut

    float *hA=(float*)malloc(bytes), *hB=(float*)malloc(bytes), *hC=(float*)malloc(bytes);
    for (int i=0;i<M*K;++i) hA[i]=1.0f;
    for (int i=0;i<K*N;++i) hB[i]=1.0f;

    float *dA,*dB,*dC;
    checkCudaErrors( cudaMalloc(&dA,bytes) );
    checkCudaErrors( cudaMalloc(&dB,bytes) );
    checkCudaErrors( cudaMalloc(&dC,bytes) );
    checkCudaErrors( cudaMemcpy(dA,hA,bytes,cudaMemcpyHostToDevice) );
    checkCudaErrors( cudaMemcpy(dB,hB,bytes,cudaMemcpyHostToDevice) );

    dim3 block(16,16);
    dim3 grid( (N+block.x-1)/block.x, (M+block.y-1)/block.y );

    double flop = 2.0*M*N*K;

    // ===== İYİ (coalesced) =====
    float ms_good = repeat( [&](){ gemm_coalesced<<<grid,block>>>(dA,dB,dC,M,N,K); }, 20, 5 );
    checkCudaErrors( cudaGetLastError() );
    checkCudaErrors( cudaDeviceSynchronize() );
    checkCudaErrors( cudaMemcpy(hC,dC,bytes,cudaMemcpyDeviceToHost) );
    bool ok_good = check(hC, M*N, (float)K);
    double s_good = (ms_good/20.0)/1000.0;

    // ===== BOZUK (uncoalesced) =====
    float ms_bad = repeat( [&](){ gemm_uncoalesced<<<grid,block>>>(dA,dB,dC,M,N,K); }, 20, 5 );
    checkCudaErrors( cudaGetLastError() );
    checkCudaErrors( cudaDeviceSynchronize() );
    checkCudaErrors( cudaMemcpy(hC,dC,bytes,cudaMemcpyDeviceToHost) );
    bool ok_bad = check(hC, M*N, (float)K);
    double s_bad = (ms_bad/20.0)/1000.0;

    // ===== Sonuçlar =====
    printf("COALESCED  : %s | %.3f ms | %.1f GFLOP/s (tepe %.1f%%)\n",
           ok_good?"OK":"HATA", ms_good/20, gflops(flop,s_good), gflops(flop,s_good)/8140*100);
    printf("UNCOALESCED: %s | %.3f ms | %.1f GFLOP/s (tepe %.1f%%)\n",
           ok_bad?"OK":"HATA", ms_bad/20, gflops(flop,s_bad), gflops(flop,s_bad)/8140*100);
    printf("Coalesced, uncoalesced'in %.1f KATI hizli\n",
           gflops(flop,s_good)/gflops(flop,s_bad));

    free(hA);free(hB);free(hC);
    cudaFree(dA);cudaFree(dB);cudaFree(dC);
    return 0;
}
