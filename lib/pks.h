#ifndef _PKS_H_
#define _PKS_H_
#include <vector>
#include "graph.h"

void pks(const CsrGraph* graph, const std::vector<std::vector<int>> query_vertices, 
        CooGraph** result, const int k, const float alpha = 0.1f, 
        const  char* filename = nullptr);

void expand(const CsrGraph* graph, const int* frontier, int* F_identifier, int* M, int* C_identifier, const int* min_activations, 
            int bfs_level, int alpha, float avg_hops, const std::vector<std::vector<int>> keyword_nodes, int query_num);

  
#endif
