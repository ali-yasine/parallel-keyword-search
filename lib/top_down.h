#ifndef __TOP_DOWN_H__
#define __TOP_DOWN_H__
#include <vector>
#include "graph.h"
#define ull unsigned long long

void topdown_construct(const CsrGraph* graph, CooGraph** result, const bool* C_identifier, const int* M, const int query_num, const int k, const std::vector<std::unordered_set<int>> keyword_nodes, const int* min_activations, const float* node_weights);

void level_cover(CooGraph*& graph, const std::vector<std::unordered_set<int>> keyword_nodes, const int central_node);

void topdown_construct(const CsrGraph* graph, CooGraph** result, const ull* C_identifier, const int* M, const int query_num, const int k, const std::vector<std::unordered_set<int>> keyword_nodes, const int* min_activations, const float* node_weights);

#endif