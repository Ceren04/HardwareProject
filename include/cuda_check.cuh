#pragma once
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>

#define checkCudaErrors(call)                                        \
    do {                                                             \
        cudaError_t err = (call);   /* çağrıyı BİR kez çalıştır */   \
        if (err != cudaSuccess) {                                    \
        printf("CUDA hata: %s:%d - %s\n", __FILE__, __LINE__, cudaGetErrorString(err)); \
              exit(EXIT_FAILURE);                                    \
        }                                                            \
    } while (0)
