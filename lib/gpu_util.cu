#include <unordered_set>
#include <vector>
#include <cassert>
#include <cmath>
#include <iostream>

#include "gpu_util.h"
#include "graph.h"

#define MAX_THREADS 1024
#define INF 2147483647
#define ull unsigned long long

CsrGraph* createEmptyCsrGPU(int num_nodes, int num_edges) {
    CsrGraph graph_shadow;
    graph_shadow.num_nodes = num_nodes;
    graph_shadow.num_edges = num_edges;

    cudaMalloc((void**)&graph_shadow.row_offsets, (num_nodes + 1) * sizeof(int));
    cudaMalloc((void**)&graph_shadow.col_indices, num_edges * sizeof(int));
    cudaMalloc((void**)&graph_shadow.edge_labels, num_edges * sizeof(int));

    CsrGraph* graph;
    cudaMalloc((void**)&graph, sizeof(CsrGraph));
    cudaMemcpy(graph, &graph_shadow, sizeof(CsrGraph), cudaMemcpyHostToDevice);
    cudaDeviceSynchronize();
    return graph;
}

void copyCsrGraphToDevice(const CsrGraph* graph, CsrGraph* graph_d) {
    CsrGraph graph_shadow;

    cudaMemcpy(&graph_shadow, graph_d, sizeof(CsrGraph), cudaMemcpyDeviceToHost);
    assert(graph_shadow.num_nodes == graph->num_nodes);
    assert(graph_shadow.num_edges == graph->num_edges);

    cudaMemcpy(graph_shadow.row_offsets, graph->row_offsets, (graph->num_nodes + 1) * sizeof(int), cudaMemcpyHostToDevice);

    cudaMemcpy(graph_shadow.col_indices, graph->col_indices, graph->num_edges * sizeof(int), cudaMemcpyHostToDevice);

    cudaMemcpy(graph_shadow.edge_labels, graph->edge_labels, graph->num_edges * sizeof(int), cudaMemcpyHostToDevice);
}


void freeCsrGPU(CsrGraph* graph) {
    cudaFree(graph->row_offsets);
    cudaFree(graph->col_indices);
    cudaFree(graph->edge_labels);
    cudaFree(graph);
}


__global__ void countTruesKernel(const bool* array, int size, int* count){
    int tid = blockIdx.x * blockDim.x + threadIdx.x;

    if (tid < size)
    {
        if (array[tid])
        {
            atomicAdd(count, 1);
        }
    }
}

int countOnesGPU(const bool* array, int size)
{
    // Allocate memory on the GPU for the array and count variables
    int* count_d;
    cudaMalloc((void**)&count_d, sizeof(int));

    // Initialize the count to 0
    auto err = cudaMemset(count_d, 0, sizeof(int));

    if (err != cudaSuccess)
    {
        // Handle cudaMemset error
        std::cerr << "Error during cudaMemset countOnes: " << cudaGetErrorString(err) << "\n";
    }

    // Launch the CUDA kernel
    int threadsPerBlock = MAX_THREADS;
    int blocksPerGrid = (size + threadsPerBlock - 1) / threadsPerBlock;

    countTruesKernel<<<blocksPerGrid, threadsPerBlock>>>(array, size, count_d);

    cudaDeviceSynchronize();

    // Copy the result (count) back to the host
    int count;
    cudaMemcpy(&count, count_d, sizeof(int), cudaMemcpyDeviceToHost);

    // Free the allocated memory on the GPU
    cudaFree(count_d);

    return count;
}



void init_keyword_nodes_and_M_onGPU(bool* keyword_nodes_d, int* M_d, int num_nodes, int query_num, const std::vector<std::unordered_set<int>>& keyword_nodes) {

    cudaError_t err;
    bool* keyword_nodes_h = (bool*) calloc(num_nodes, sizeof(bool));

    int* M_h = (int*) malloc(num_nodes * query_num * sizeof(int));
    
    for(int i = 0; i < num_nodes * query_num; i++) {
        M_h[i] = INF;
    }
    

    for (int i = 0; i < query_num; i++) {
        for (auto node : keyword_nodes[i]) {
            keyword_nodes_h[node] = true;
            M_h[node * query_num + i] = 0;
        }
    }

    //count number of keyword nodes
    int num_keyword_nodes = 0;

    for (int i = 0; i < num_nodes; i++) {
        if (keyword_nodes_h[i]) {
            num_keyword_nodes++;
        }
    }


    cudaMemcpy(keyword_nodes_d, keyword_nodes_h, num_nodes * sizeof(bool), cudaMemcpyHostToDevice);
    cudaMemcpy(M_d, M_h, num_nodes * query_num * sizeof(int), cudaMemcpyHostToDevice);
    err = cudaGetLastError();
    if (err != cudaSuccess) {
        // Handle cudaMemcpy error
        std::cerr << "Error during cudaMemcpy: " << cudaGetErrorString(err) << std::endl;
        // Clean up allocated memory
        free(M_h);
        free(keyword_nodes_h);
        return;
    }

    cudaDeviceSynchronize();
    
    free(M_h);
    free(keyword_nodes_h);
}


void init_M_keywords_bitwise(ull* keyword_nodes_d, int* M_d, int num_nodes, int query_num, const std::vector<std::unordered_set<int>>& keyword_nodes) {


    cudaError_t err;
    int num_nodes_ull = (num_nodes + 64 - 1) / 64;

    ull* keyword_nodes_h = (ull*) calloc(num_nodes_ull, sizeof(ull));

    int* M_h = (int*) malloc(num_nodes * query_num * sizeof(int));

    for(int i = 0; i < num_nodes * query_num; i++) {
        M_h[i] = INF;
    }

    for (int i = 0; i < query_num; i++) {
        for (auto node : keyword_nodes[i]) {
            keyword_nodes_h[node / 64] |= (1ULL << (node % 64));
            M_h[node * query_num + i] = 0;
        }
    }

    cudaMemcpy(keyword_nodes_d, keyword_nodes_h, num_nodes_ull * sizeof(ull), cudaMemcpyHostToDevice);
    cudaMemcpy(M_d, M_h, num_nodes * query_num * sizeof(int), cudaMemcpyHostToDevice);
    err = cudaGetLastError();

    if (err != cudaSuccess) {
        // Handle cudaMemcpy error
        std::cerr << "Error during cudaMemcpy: " << cudaGetErrorString(err) << std::endl;
        // Clean up allocated memory
        free(M_h);
        free(keyword_nodes_h);
        return;
    }

    cudaDeviceSynchronize();
    free(M_h);
    free(keyword_nodes_h);

}

__device__ int getActivationLevel_gpu(const float node_weight, float alpha, float avg_hops) {

    float epsilon = 0.0001f;

    //check if node_weight = alpha
    if (fabsf(node_weight - alpha) < epsilon) {
        return (int) roundf(avg_hops);
    }

    if (node_weight < alpha) {
        float reward = avg_hops * (alpha - node_weight) / alpha;
        return (int) roundf(avg_hops - reward);
    }

    float penalty = avg_hops * (node_weight - alpha) / (1.0f - alpha); 

    return (int) roundf(avg_hops + penalty);

}

__global__ void get_min_activations_kernel(const float* node_weights, int num_nodes, float alpha, int avg_hops, int* min_activations) {

    int thread_id = blockIdx.x * blockDim.x + threadIdx.x;
    if (thread_id < num_nodes) {
        min_activations[thread_id] = getActivationLevel_gpu(node_weights[thread_id], alpha, avg_hops);
    }
}

void get_min_activations_gpu(const float* node_weights, const int num_nodes, const float alpha, const float avg_hops, int* min_activations_d) {
    
    const unsigned int num_threads = MAX_THREADS;
    const unsigned int num_blocks = ((num_nodes) + num_threads - 1) / num_threads;

    float* node_weights_d;
    cudaMalloc((void**)&node_weights_d, num_nodes * sizeof(float));
    cudaMemcpy(node_weights_d, node_weights, num_nodes * sizeof(float), cudaMemcpyHostToDevice);

    get_min_activations_kernel <<<num_blocks, num_threads >>> (node_weights_d, num_nodes, alpha, avg_hops, min_activations_d);

    cudaFree(node_weights_d);
}


void enqueue_frontier_gpu(int num_nodes, bool* F_identifier_d, bool* frontier_d) {
    //copy F_identifier_d to frontier_d
    
    auto err = cudaMemcpy(frontier_d, F_identifier_d, num_nodes * sizeof(bool), cudaMemcpyDeviceToDevice);
    
    if (err != cudaSuccess) {
        // Handle cudaMemcpy error
        std::cerr << "Error during cudaMemcpy enque_frontier: " << cudaGetErrorString(err) << "\n";
    }

    err = cudaMemset(F_identifier_d, 0, num_nodes * sizeof(bool));

    if (err != cudaSuccess) {
        // Handle cudaMemset error
        std::cerr << "Error during cudaMemset enque_frontier: " << cudaGetErrorString(err) << "\n";
    }
    
}

void enqueue_frontier_bitwise(int num_nodes, ull* F_identifier_d, ull* frontier_d) {

    int num_nodes_ull = (num_nodes + 64 - 1) / 64;

    auto err = cudaMemcpy(frontier_d, F_identifier_d, num_nodes_ull * sizeof(ull), cudaMemcpyDeviceToDevice);

    if (err != cudaSuccess) {
        // Handle cudaMemcpy error
        std::cerr << "Error during cudaMemcpy enque_frontier: " << cudaGetErrorString(err) << "\n";
    }

    err = cudaMemset(F_identifier_d, 0, num_nodes_ull * sizeof(ull));

    if (err != cudaSuccess) {
        // Handle cudaMemset error
        std::cerr << "Error during cudaMemset enque_frontier: " << cudaGetErrorString(err) << "\n";
    }

}

__global__ void identify_central_kernel(int num_nodes, bool* C_identifier, bool* F_identifier, int* M, int query_num) {
    
    int node = blockIdx.x * blockDim.x + threadIdx.x;
    if (node < num_nodes) {
        if (F_identifier[node]) {
            bool is_central = true;
            for (int i = 0; i < query_num; i++) {
                if (M[node * query_num + i] == INF) {
                    is_central = false;
                    break;
                }
            }
            if (is_central) {
                C_identifier[node] = true;
            }
        }
    }
}


void identify_central_gpu(int num_nodes, bool* C_identifier_d, bool* F_identifier_d, int* M_d, int query_num) {
    const unsigned int num_threads = MAX_THREADS;
    const unsigned int num_blocks = ((num_nodes) + num_threads - 1) / num_threads;

    identify_central_kernel << <num_blocks, num_threads >> > (num_nodes, C_identifier_d, F_identifier_d, M_d, query_num);

    cudaDeviceSynchronize();   
}


__global__ void identify_central_bitwise_kernel(int num_nodes, ull* C_identifier, ull* F_identifier, int* M, int query_num) {

    int node = blockIdx.x * blockDim.x + threadIdx.x;
    if (node < num_nodes) {
        if (F_identifier[node / 64] & (1ULL << (node % 64))) {
            bool is_central = true;
            for (int i = 0; i < query_num; i++) {
                if (M[node * query_num + i] == INF) {
                    is_central = false;
                    break;
                }
            }
            if (is_central) {
                atomicOr(&C_identifier[node / 64], 1ULL << (node % 64));
            }
        }
    }
}


void identify_central_bitwise(int num_nodes, ull* C_identifier_d, ull* F_identifier_d, int* M_d, int query_num) {
    const unsigned int num_threads = MAX_THREADS;
    const unsigned int num_blocks = ((num_nodes) + num_threads - 1) / num_threads;

    identify_central_bitwise_kernel << <num_blocks, num_threads >> > (num_nodes, C_identifier_d, F_identifier_d, M_d, query_num);

    cudaDeviceSynchronize();
}


void dequeue_frontier_gpu(bool* frontier_d, int num_nodes) {
    cudaMemsetAsync(frontier_d, 0, num_nodes * sizeof(bool));
}

void dequeue_frontier_bitwise(ull* frontier_d, int num_nodes) {
    int num_nodes_ull = (num_nodes + 64 - 1) / 64;
    cudaMemsetAsync(frontier_d, 0, num_nodes_ull * sizeof(ull));
}

bool check_terminate_gpu(bool* C_identifier_d, int num_nodes, int k) {


    int count = countOnesGPU(C_identifier_d, num_nodes);
            
    return count >= k;
}

__global__ void countOnesBitwiseGPU(ull* C_identifier, int num_nodes_ull, int* count) {
    int node = blockIdx.x * blockDim.x + threadIdx.x;
    if (node < num_nodes_ull) {

        int num_centrals = __popcll(C_identifier[node]);

        if (num_centrals > 0)
            atomicAdd(count, num_centrals);
    }
}


bool check_terminate_bitwise(ull* C_identifier_d, int num_nodes, int k) {

    int num_nodes_ull = (num_nodes + 64 - 1) / 64;

    int threadsPerBlock = MAX_THREADS;
    int numBlocks = (num_nodes_ull + threadsPerBlock - 1) / threadsPerBlock;

    int* count_d; 
    cudaMalloc((void**)&count_d, sizeof(int));

    cudaMemset(count_d, 0, sizeof(int));

    countOnesBitwiseGPU << <numBlocks, threadsPerBlock >> > (C_identifier_d, num_nodes_ull, count_d);

    int count;

    cudaMemcpy(&count, count_d, sizeof(int), cudaMemcpyDeviceToHost);


    cudaFree(count_d);

    return count >= k;
}

void cudaFreeGraph(CsrGraph* graph_d) {
    cudaFree(graph_d->row_offsets);
    cudaFree(graph_d->col_indices);
    cudaFree(graph_d->edge_labels);
    cudaFree(graph_d);
}


__global__ void init_M_kernel(bool* is_keyword_d, int* M_d, int num_nodes, int query_num) {
    int node = blockIdx.x * blockDim.x + threadIdx.x;
    if (node < num_nodes) {
        if (is_keyword_d[node]) {
            for (int i = 0; i < query_num; i++) {
                M_d[node * query_num + i] = 0;
            }
        }
        else {
            for (int i = 0; i < query_num; i++) {
                M_d[node * query_num + i] = INF;
            }
        }
    }
}

void init_M_gpu(bool* is_keyword_d, int* M_d, int num_nodes, int query_num) {
    const unsigned int num_threads = MAX_THREADS;
    const unsigned int num_blocks = ((num_nodes) + num_threads - 1) / num_threads;

    init_M_kernel << <num_blocks, num_threads >> > (is_keyword_d, M_d, num_nodes, query_num);

    cudaDeviceSynchronize();
}