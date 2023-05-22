#ifndef GPU_UTIL_H
#define GPU_UTIL_H

#include "graph.h"
#include <unordered_set>
#include <vector>
#define ull unsigned long long
CsrGraph* createEmptyCsrGPU(int num_nodes, int num_edges);

void copyCsrGraphToDevice(const CsrGraph* graph, CsrGraph* graph_d);

void freeCsrGPU(CsrGraph* graph);

void init_keyword_nodes_and_M_onGPU(bool* keyword_nodes_d, int* M_d, int num_nodes, int query_num, const std::vector<std::unordered_set<int>>& keyword_nodes);

void get_min_activations_gpu(const float* node_weights, const int num_nodes, const float alpha, const float avg_hops, int* min_activations_d);

void enqueue_frontier_gpu(int num_nodes, bool* F_identifier_d, bool* frontier_d);

void identify_central_gpu(int num_nodes, bool* C_identifier_d, bool* F_identifier_d, int* M_d, int query_num);

void dequeue_frontier_gpu(bool* frontier_d, int num_nodes);

bool check_terminate_gpu(bool* C_identifier_d, int num_nodes, int k);

int countOnesGPU(const bool* array, int size);

void cudaFreeGraph(CsrGraph* graph_d);

void init_M_keywords_bitwise(ull* keyword_nodes_d, int* M_d, int num_nodes, int query_num, const std::vector<std::unordered_set<int>>& keyword_nodes);

void enqueue_frontier_bitwise(int num_nodes, ull* F_identifier_d, ull* frontier_d);

void dequeue_frontier_bitwise(ull* frontier_d, int num_nodes);

void identify_central_bitwise(int num_nodes, ull* C_identifier_d, ull* F_identifier_d, int* M_d, int query_num);

bool check_terminate_bitwise(ull* C_identifier_d, int num_nodes, int k);

#endif