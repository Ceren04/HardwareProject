# Faz 0 — Gün 7: Metrik → Kavram → Çözüm Haritası

GEMM tırmanışında darboğazları tespit edip çözmek için kullanılacak referans tablosu:

| Gözlem (Metrik) | Ne Anlama Gelir? | Araştırılacak Kavram / Çözüm |
|---|---|---|
| Memory-bound + düşük DRAM verimi | Trafik var ama bellek erişimi verimsiz (dağınık) gerçekleşiyor. | Memory coalescing, erişim deseni (stride), hizalama (alignment). |
| Memory-bound + yüksek DRAM verimi | Bellek tavanına ulaşıldı, veri taşıma hızı sınırda. | Trafiği azaltmak için Shared Memory tiling, veri yeniden kullanımı (cache blocking). |
| Düşük Achieved Occupancy | SM'ler (Streaming Multiprocessors) boş kalıyor, yeterli warp içeri alınamıyor. | Register kullanımı (register spilling), block boyutu optimizasyonu (çok küçük/büyük bloklar), occupancy hesaplayıcı. |
| Compute-bound ama tepeden uzak | İşlem birimleri dolu görünüyor ancak verimli kullanılmıyor (boşta bekleme). | Instruction-level parallelism (ILP), warp divergence (dallanma sapmaları), dead code elimination kontrolü. |
| Shared memory kullanıldı ama yavaşladı | Hızlı belleğe aynı anda aynı adresten/banktan erişilmeye çalışılıyor ve işlemler sıraya giriyor (serileşiyor). | Bank conflict, padding (doldurma) teknikleri, bellek düzeni. |
