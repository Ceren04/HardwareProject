#pragma once
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
