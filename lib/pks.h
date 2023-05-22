#ifndef _PKS_H_
#define _PKS_H_
#include <vector>
#include <unordered_set>
#include "graph.h"
#define ull unsigned long long

void pks(const CsrGraph* graph,  const std::vector<std::unordered_set<int>>& keyword_nodes, 
        CooGraph** result, const int k, const float alpha,  const float* node_weights, const int* min_activations, const float avg_hops);

void expand(const CsrGraph* graph, const bool* frontier, bool* F_identifier, int* M, bool* C_identifier, const int* min_activations, int bfs_level, const float alpha, const float avg_hops,  bool* keyword_nodes, int query_num);

void pks_gpu(const CsrGraph* graph, const CsrGraph* graph_d,  const std::vector<std::unordered_set<int>>& keyword_nodes, CooGraph **result, const int k, const float alpha, const float *node_weights, const int* min_activations_h, const int* min_activations_d, const float avg_hops);

void expand_gpu(const CsrGraph* graph_d, const bool* frontier_d, bool* F_identifier_d, int* M_d, bool* C_identifier_d, const int* min_activations_d, int bfs_level, float alpha, float avg_hops, const bool* keyword_nodes_d, int query_num, int num_nodes);

void pks_gpu_bitwise(const CsrGraph *graph, const CsrGraph* graph_d,  const std::vector<std::unordered_set<int>>& keyword_nodes, CooGraph **result, const int k, const float alpha, const float *node_weights, const int* min_activations_h, const int* min_activations_d, const float avg_hops);

void expand_bitwise(const CsrGraph* graph_d, const ull* frontier_d, ull* F_identifier_d, int* M_d, ull* C_identifier_d, const int* min_activations_d, int bfs_level, float alpha, float avg_hops, const ull* keyword_nodes_d, int query_num, int num_nodes);

  
#endif
