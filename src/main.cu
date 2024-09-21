#include <cuda.h>
#include <cuda_runtime.h>
#include <curand_kernel.h>
#include <stdint.h>
#include <stdio.h>
#include <getopt.h>
#include <string.h>
#include "sha3.cuh"
#define BLOCKS 128
#define THREADS 256
#define N 100000000000  
__device__ int lock = 0;  
__device__ void lock_acquire() {
    while (atomicCAS(&lock, 0, 1) != 0) {
        __threadfence();  
    }
}
__device__ void lock_release() {
    atomicExch(&lock, 0);  
}
// Fixed constants (Host side only)
__constant__ uint8_t DIFFICULTY[4] = {0x22, 0x33, 0x99,0x99};
__constant__ uint8_t CURRENT_CHALLENGE[32] = {0x78, 0x90, 0x55, 0x58, 0x00, 0x90, 0x00, 0x90,
                                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
__constant__ uint8_t MINER_ADDRESS[20] = {
    0x32, 0xb2, 0xc3, 0xee, 0x46, 0xa6, 0x56, 0x65,
    0x28, 0x2d, 0xbd, 0x50, 0x32, 0x8a, 0xfa, 0x46,
    0x79, 0xec, 0x17, 0x86
};

// Device function to check if hash matches difficulty
__device__ char int_to_hex(int i) {
    if (i < 10) return '0' + i;
    return 'a' + (i - 10);
}

__device__ void byte_to_hex(uint8_t byte, char* output) {
    output[0] = int_to_hex((byte >> 4) & 0xF);
    output[1] = int_to_hex(byte & 0xF);
}

__global__ void calculate() {
    int tid = threadIdx.x + blockIdx.x * blockDim.x;
    __shared__ uint8_t shared_difficulty[3];
    __shared__ uint8_t shared_challenge[32];
    __shared__ uint8_t shared_miner_address[20];
    if (threadIdx.x < 3) shared_difficulty[threadIdx.x] = DIFFICULTY[threadIdx.x];
    if (threadIdx.x < 32) shared_challenge[threadIdx.x] = CURRENT_CHALLENGE[threadIdx.x];
    if (threadIdx.x < 20) shared_miner_address[threadIdx.x] = MINER_ADDRESS[threadIdx.x];
    __syncthreads();
    curandState state;
    curand_init((unsigned long long)clock() + tid, 0, 0, &state);
    //uint8_t dev_difficulty[4] = {DIFFICULTY[0], DIFFICULTY[1], DIFFICULTY[2], DIFFICULTY[3]};
    //uint8_t local_challenge[32];
    //uint8_t local_miner_address[20];
    //memcpy(local_challenge, shared_challenge, 32);
    //memcpy(local_miner_address, shared_miner_address, 20);
    uint64_t block = (uint64_t)(curand_uniform_double(&state) * UINT64_MAX);
    uint8_t data[96];
    uint8_t hash[32];
    uint8_t blockBytes[32];
    memcpy(&data[32], shared_challenge, 32);
    memset(&data[64], 0, 12);
    memcpy(&data[76], shared_miner_address, 20);  
    for (uint64_t i = 0; i < N; i++) {
        
        for (int j = 0; j < 32; j++) {
            //blockBytes[j] = curand(&state) & 0xFF;
            ((uint32_t*)blockBytes)[j] = curand(&state);
            //((uint32_t*)blockBytes)[j] ^= (curand(&state) << 16);
            //blockBytes[j] ^= (curand(&state) << 16);

        }
        memcpy(data, blockBytes, 32);
        sha3_return_t ok = sha3_HashBuffer(256, SHA3_FLAGS_KECCAK, data, 96, hash, 32);
        if (ok != 0) {
            printf("bad params\n");
            return;
        }
        bool match = true;

        for(int j = 0; j<3; j++){
            if(hash[j] != shared_difficulty[j]){
                match = false;
                break;
            }
        }
        if (match) {
            lock_acquire();
            //char result1[65];  // 32 bytes * 2 chars per byte + 1 null terminator
            //for (int j = 0; j < 32; j++) {
            //    byte_to_hex(hash[j], &result1[j*2]);
            //}
            //result1[64] = '\0'; 
            //printf("thread => %d hash :0x%s\n", tid, result1);
            
            char result[65];  // 32 bytes * 2 chars per byte + 1 null terminator
            for (int j = 0; j < 32; j++) {
                byte_to_hex(blockBytes[j], &result[j*2]);
            }
            result[64] = '\0'; 
            printf("thread => %d randomValue :0x%s\n", tid, result);
            lock_release();
        }
    }
}

int main(int argc, char *argv[]) {
	int opt;
	int poolIndex = -1; 
    //0x32b2C3eE46A65665282DbD50328AFA4679eC1786
	uint8_t MINER_ADDRESS1[20] = {0x32, 0xb2, 0xc3, 0xee, 0x46, 0xa6, 0x56, 0x65,0x28, 0x2d, 0xbd, 0x50, 0x32, 0x8a, 0xfa, 0x46,0x79, 0xec, 0x17, 0x86};
	uint8_t MINER_ADDRESS2[20] = {0x9f, 0x07, 0xd1, 0x4c, 0x88, 0xeb, 0x4f, 0x11, 0x1c, 0x9f, 0x9c, 0xc7, 0x66, 0x39, 0xb7, 0xca, 0xeb, 0x62, 0x2b, 0x4b};
	uint8_t MINER_ADDRESS3[20] = {0xd3, 0x79, 0xed, 0x77, 0x39, 0x39, 0x67, 0x58, 0x7e, 0x54, 0xf5, 0x0a, 0x4e, 0xf6, 0x28, 0xda, 0x08, 0x41, 0x7c, 0xb5};
	uint8_t MINER_ADDRESS4[20] = {0x6f, 0xcd, 0x09, 0x8f, 0x3c, 0x21, 0x21, 0x9b, 0x57, 0x2a, 0x5a, 0x1a, 0xf1, 0xfc, 0x82, 0xd2, 0x3f, 0x89, 0x23, 0xd7};
	while ((opt = getopt(argc, argv, "p:")) != -1) {
        switch (opt) {
            case 'p':
                poolIndex = atoi(optarg); 
                break;
            default:
                fprintf(stderr, "Usage: %s -p <pool_index (1-4)>\n", argv[0]);
                exit(EXIT_FAILURE);
        }
    }
	if (poolIndex < 1 || poolIndex > 4) {
        fprintf(stderr, "Invalid pool index. Please provide a value between 1 and 4.\n");
        exit(EXIT_FAILURE);
    }
	uint8_t *selectedMinerAddress;
    switch (poolIndex) {
        case 1: selectedMinerAddress = MINER_ADDRESS1; break;
        case 2: selectedMinerAddress = MINER_ADDRESS2; break;
        case 3: selectedMinerAddress = MINER_ADDRESS3; break;
        case 4: selectedMinerAddress = MINER_ADDRESS4; break;
    }
    cudaMemcpyToSymbol(DIFFICULTY, "\x12\x34\x88", 3);
    cudaMemcpyToSymbol(CURRENT_CHALLENGE, "\x78\x90\x55\x58\x00\x90\x00\x90\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", 32);
    cudaMemcpyToSymbol(MINER_ADDRESS, selectedMinerAddress, 20);
    calculate<<<BLOCKS, THREADS>>>();
    cudaDeviceSynchronize();
    exit(EXIT_SUCCESS);
}
