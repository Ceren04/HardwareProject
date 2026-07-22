#include <cstdio>
#include <cuda_runtime.h>

int main() {
    int dev = 0;
    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, dev);

    printf("Kart: %s\n", prop.name);
    printf("Compute capability: %d.%d\n", prop.major, prop.minor);
    printf("SM sayisi: %d\n", prop.multiProcessorCount);
    printf("Warp boyutu: %d\n", prop.warpSize);
    printf("Global bellek: %.2f GB\n", prop.totalGlobalMem / (1024.0*1024.0*1024.0));
    printf("Shared mem/blok: %zu bayt\n", prop.sharedMemPerBlock);
    printf("SM başına maksimum thread: %d\n", prop.maxThreadsPerMultiProcessor);
    printf("Register / SM: %d \n", prop.regsPerMultiprocessor);
    printf("sharedMemory / SM: %zu bayt \n", prop.sharedMemPerMultiprocessor);
    printf("memoryBusWidth: %d \n", prop.memoryBusWidth);

  int clk, memClk, busWidth;
      cudaDeviceGetAttribute(&clk, cudaDevAttrClockRate, dev);
      cudaDeviceGetAttribute(&memClk, cudaDevAttrMemoryClockRate, dev);
      // Veri yolu genişliğini bit cinsinden al (Örn: 128-bit, 256-bit)
      cudaDeviceGetAttribute(&busWidth, cudaDevAttrGlobalMemoryBusWidth, dev);

      printf("SM saati: %.0f MHz\n", clk / 1000.0);
      
      // Bellek saatini yazdir
      printf("Bellek saati: %.0f MHz\n", memClk / 1000.0);

      // Teorik bant genisligini hesapla ve yazdir
      // memClk (kHz) * 2 (GDDR6 veri hızı çarpanı) * busWidth (bit) / 8 (Byte'a çevrim) / 1000000 (GB/sn'ye çevrim)
      double bandwidthGBs = ((double)memClk * 2.0 * busWidth) / (8.0 * 1.0e6);
      
      printf("Bellek Veri Yolu Genişliği: %d bit\n", busWidth);
      printf("Teorik Bellek Bant Genişliği: %.2f GB/s\n", bandwidthGBs);

    return 0;
}
