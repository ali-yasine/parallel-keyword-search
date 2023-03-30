#ifndef __TOP_DOWN_H__
#define __TOP_DOWN_H__
#include <vector>
#include "graph.h"

void topdown_construct(const CsrGraph* graph, CooGraph** result, const int* C_identifier, const int* M, const int query_num, const int k, const std::vector<std::vector<int>> keyword_nodes, const int* min_activations, const float* node_weights);

void level_cover(CooGraph* graph );


#endif