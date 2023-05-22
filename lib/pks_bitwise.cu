#include <iostream>
#include <vector>
#include <unordered_set>
#include "graph.h"
#include "pks.h"
#include "util.h"
#include "index.h"
#include "timer.h"
#include "top_down.h"
#include "gpu_util.h"
#include "top_down.h"
#define INF 2147483647
#define ull unsigned long long
#define MAX_THREADS 1024

void pks_gpu_bitwise(const CsrGraph *graph, const CsrGraph* graph_d,  const std::vector<std::unordered_set<int>>& keyword_nodes, CooGraph **result, const int k, const float alpha, const float *node_weights, const int* min_activations_h, const int* min_activations_d, const float avg_hops){
    cudaError_t err; Timer timer;


    int query_num = keyword_nodes.size();
    int num_nodes = graph->num_nodes;


    startTime(&timer);
    // allocate memory for graph

    int *M_d;
    unsigned long long* frontier_d, *F_identifier_d, *C_identifier_d;
    unsigned long long* keyword_nodes_d;


    //allocate memory


    int num_nodes_longlong = (num_nodes + 64 - 1 )  / 64;

    err = cudaMalloc((void **)&frontier_d, (num_nodes_longlong) * sizeof(ull));
    if (err != cudaSuccess){
        // Handle memory allocation error
        std::cerr << "Error allocating memory for frontier_d" << std::endl;
    }

    err = cudaMalloc((void **)&F_identifier_d, num_nodes_longlong * sizeof(ull));
    if (err != cudaSuccess){
        // Handle memory allocation error
        std::cerr << "Error allocating memory for F_identifier_d" << std::endl;
    }

    err = cudaMalloc((void **)&C_identifier_d, num_nodes_longlong * sizeof(ull));
    if (err != cudaSuccess){
        // Handle memory allocation error
        std::cerr << "Error allocating memory for C_identifier_d" << std::endl;
    }

    err = cudaMalloc((void **)&keyword_nodes_d, num_nodes_longlong * sizeof(ull));
    if (err != cudaSuccess){
        // Handle memory allocation error
        std::cerr << "Error allocating memory for keyword_nodes_d" << std::endl;
    }

    err = cudaMalloc((void **)&M_d, sizeof(int) * num_nodes * query_num);
    if (err != cudaSuccess){
        // Handle memory allocation error
        std::cerr << "Error allocating memory for M_d" << std::endl;
    }

    // Check if any memory allocation failed
    if (err != cudaSuccess) {
        // Clean up allocated memory
        cudaFree(M_d);
        cudaFree(keyword_nodes_d);
        cudaFree(C_identifier_d);
        cudaFree(F_identifier_d);
        cudaFree(frontier_d);
        // Return or throw an appropriate error
        return;
    }

    err = cudaMemsetAsync(frontier_d, 0, num_nodes_longlong * sizeof(ull));
    if (err != cudaSuccess){
        // Handle memory initialization error
        std::cerr << "Error initializing frontier_d" << std::endl;
    }

    err = cudaMemsetAsync(C_identifier_d, 0, num_nodes_longlong * sizeof(ull));
    if (err != cudaSuccess){
        // Handle memory initialization error
        std::cerr << "Error initializing C_identifier_d" << std::endl;
    }


    init_M_keywords_bitwise(keyword_nodes_d, M_d, num_nodes, query_num, keyword_nodes);

    err = cudaGetLastError();
    if (err != cudaSuccess){
        // Handle memory initialization error
        std::cerr << "cuda error: " << cudaGetErrorString(err) << "\n";
    }

    cudaMemcpy(F_identifier_d, keyword_nodes_d, num_nodes_longlong * sizeof(ull) , cudaMemcpyDeviceToDevice);
    
    int BFS_level = 0;
    bool terminate = false;
    std::cerr << "starting gpu expansion\n";

    stopTime(&timer);
    printElapsedTime(timer, "gpu copy and init time: ");

    startTime(&timer);

    while (!terminate){
        enqueue_frontier_bitwise(num_nodes, F_identifier_d, frontier_d);

        // TODO
        expand_bitwise(graph_d, frontier_d, F_identifier_d, M_d, C_identifier_d, min_activations_d, BFS_level, alpha, avg_hops, keyword_nodes_d, query_num, num_nodes);

        dequeue_frontier_bitwise(frontier_d, num_nodes);

        identify_central_bitwise(num_nodes, C_identifier_d, F_identifier_d, M_d, query_num);

        BFS_level++;

        terminate = check_terminate_bitwise(C_identifier_d, num_nodes, k);
    }
    stopTime(&timer);

    printElapsedTime(timer, "gpu expansion time: ");
    // copy back to host

    startTime(&timer);

    int *M = (int *)malloc(sizeof(int) * num_nodes * query_num);
    cudaMemcpy(M, M_d, sizeof(int) * num_nodes * query_num, cudaMemcpyDeviceToHost);

    ull *C_identifier_h = (ull* ) malloc(num_nodes_longlong * sizeof(ull));
    cudaMemcpy(C_identifier_h, C_identifier_d, num_nodes_longlong * sizeof(ull), cudaMemcpyDeviceToHost);

    // free memory
    cudaFree(frontier_d);
    cudaFree(F_identifier_d);
    cudaFree(C_identifier_d);
    cudaFree(keyword_nodes_d);
    cudaFree(M_d);

    std::cerr << "start topdown construct\n";

    topdown_construct(graph, result, C_identifier_h, M, query_num, k, keyword_nodes, min_activations_h, node_weights);

    std::cerr << "end topdown construct\n";

    // free memory
    free(M);
    free(C_identifier_h);
}

__global__ void expand_kernel_bitwise(const CsrGraph* graph, const ull* frontier, ull* F_identifier, int* M, ull* C_indentifier, const int* min_activations, int bfs_level, float alpha, float avg_hops, const ull* keyword_nodes, int query_num) {
    int node = blockIdx.x * blockDim.x + threadIdx.x;

    if (node < graph->num_nodes) {
        ull node_bit = (1ULL << (node % 64));
        if (frontier[node / 64] & node_bit) {
            if (!(C_indentifier[node / 64] & node_bit)) {
                int min_activation_level = min_activations[node];

                if (min_activation_level > bfs_level) {
                    atomicOr(&F_identifier[node / 64], node_bit);
                    return;
                }

                for(int bfs_instance = 0; bfs_instance < query_num; ++bfs_instance) {
                    
                    int hitting_level = M[node * query_num + bfs_instance];

                    if (hitting_level > bfs_level) {
                        continue;
                    }

                    for(int neighbor = graph->row_offsets[node]; neighbor < graph->row_offsets[node + 1]; ++neighbor) {
                        int neighbor_id = graph->col_indices[neighbor];

                        int neighbor_hitting_level = M[neighbor_id * query_num + bfs_instance];

                        if (neighbor_hitting_level != INF)
                            continue;

                        if (! (keyword_nodes[neighbor_id / 64] & node_bit ) ) {
                            int neighbor_activation_level = min_activations[neighbor_id];
                            if (neighbor_activation_level > bfs_level + 1) {
                                atomicOr(&F_identifier[neighbor_id / 64], node_bit);
                                continue;
                            }
                        }
                        M[neighbor_id * query_num + bfs_instance] = bfs_level + 1;
                        
                        atomicOr(&F_identifier[neighbor_id / 64], (1ULL << (neighbor_id % 64)));
                    }
                }
            }
        }
    }
}


void expand_bitwise(const CsrGraph* graph_d, const ull* frontier_d, ull* F_identifier_d, int* M_d, ull* C_identifier_d, const int* min_activations_d, int bfs_level, float alpha, float avg_hops, const ull* keyword_nodes_d, int query_num, int num_nodes) {

    int num_threads = MAX_THREADS; 
    int num_blocks = (num_nodes + num_threads - 1) / num_threads;

    expand_kernel_bitwise<<<num_blocks, num_threads>>>(graph_d, frontier_d, F_identifier_d, M_d, C_identifier_d, min_activations_d, bfs_level, alpha, avg_hops, keyword_nodes_d, query_num);

    cudaDeviceSynchronize();
}
