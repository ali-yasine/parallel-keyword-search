#ifndef _PKS_H_
#define _PKS_H_
#include <vector>
#include "graph.h"

void pks(const CsrGraph* graph, const std::vector<std::vector<int>> query_vertices, 
        CsrGraph** result, const int k, const float alpha = 0.1f, 
        const const char* filename = nullptr);

void expand(CsrGraph* graph, const int* frontier, int* F_identifier, int* M, 
                int* C_identifier, float* node_weight, int bfs_level, int alpha, float avg_hops);

#endif
