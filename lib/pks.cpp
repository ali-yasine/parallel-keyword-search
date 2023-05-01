#include <iostream>
#include <cmath>
#include <vector>
#include <deque>
#include <algorithm>
#include <numeric>
#include <queue>
#include <fstream>
#include <cstring>
#include <limits>
#include <unordered_set>
#include "graph.h"
#include "pks.h"
#include "util.h"
#include "index.h"
#include "Bfs.h"
#include "top_down.h"

#define INF std::numeric_limits<int>::max()


void pks(const CsrGraph* graph, const std::vector<std::vector<int>> keyword_nodes, CooGraph** result, const int k, const float alpha, const char* filename) {
    
    
    std::cerr << "starting pks\n";

    int query_num = keyword_nodes.size();
    int num_nodes = graph->num_nodes;
    float* node_weights = (float*) calloc(num_nodes, sizeof(float));
    float avg_hops = 0;

    if (filename) 
        readGraphIndex(filename, node_weights, avg_hops, num_nodes);
    else {
        getVertexInformativeness(graph, node_weights);
        avg_hops = averageDistanceInGraph(graph);
        writeGraphIndex("index/graph.txt", node_weights, avg_hops, num_nodes);
    }

    int* min_activations = (int*) calloc(num_nodes, sizeof(int));
    getMinActivations(node_weights, num_nodes, alpha, avg_hops, min_activations);
    
    //initialize F,C and M the node-keyword matrix
    int* F_identifier = (int*) calloc(num_nodes, sizeof(int));
    int* C_identifier = (int*) calloc(num_nodes, sizeof(int));
    int* M = (int*) malloc(num_nodes * query_num * sizeof(int)); 

    if (!F_identifier || !C_identifier || !M) {
        std::cerr << "cannot allocate memory\n";
        exit(1);
    }
    
    for(int i = 0; i < num_nodes * query_num; ++i) {
        M[i] = INF;
    }

    //put every query vertex into BFS instances
    for (int i = 0; i < query_num; ++i) {
        for (int j = 0; j < keyword_nodes[i].size(); ++j) {

            int node = keyword_nodes[i][j];
            
            F_identifier[node] = 1;
            M[node * query_num + i] = 0;
        }
    }
    
    int BFS_level = 0;
    bool terminate = false;
    
    int* frontier = (int*) calloc(num_nodes, sizeof(int));
    
    if (!frontier) {
        std::cerr << "cannot allocate frontier memory\n";
        exit(1);
    }
    
    int frontier_size = 0;
    std::cerr << "starting expansion loop\n";
    //print F_identifier
    
    while (!terminate) {

        enqueue_frontier(num_nodes, F_identifier, frontier,  frontier_size);

        expand(graph, frontier,  F_identifier, M, C_identifier, min_activations, BFS_level, alpha, avg_hops, keyword_nodes, query_num);

        identify_central(num_nodes, C_identifier, F_identifier, M, query_num);

        BFS_level++;

        for(int i = 0; i < num_nodes; ++i){
            frontier[i] = 0;
        }

        frontier_size = 0;

        if (std::accumulate(C_identifier, C_identifier + num_nodes, 0) >= k)
            terminate = true;       
    }

    
    std::cerr << "start topdown construct\n";
    topdown_construct(graph, result, C_identifier, M, query_num, k, keyword_nodes, min_activations, node_weights);
    

    free(F_identifier);
    free(C_identifier);
    free(M);
    free(frontier);
    free(min_activations);
}

void expand(const CsrGraph* graph, const int* frontier, int* F_identifier, int* M, int* C_identifier, const int* min_activations, 
            int bfs_level, int alpha, float avg_hops, const std::vector<std::vector<int>> keyword_nodes, int query_num) {
                
    for(int curr_node = 0; curr_node < graph->num_nodes; ++curr_node) {

        if (frontier[curr_node]) {
            
            if (C_identifier[curr_node]) 
                continue;

            int min_activation_level = min_activations[curr_node];

            if (min_activation_level > bfs_level) {
                F_identifier[curr_node] = 1;
                continue;
            }

            for(int bfs_instance = 0; bfs_instance < query_num; ++bfs_instance) {

                int hitting_level = M[curr_node * query_num + bfs_instance];

                if (hitting_level > bfs_level) 
                    continue;

                for (int neighbor = graph->row_offsets[curr_node]; neighbor < graph->row_offsets[curr_node + 1]; ++neighbor) {

                    int neighbor_id = graph->col_indices[neighbor];

                    int neighbor_hitting_level = M[neighbor_id * query_num + bfs_instance];

                    if (neighbor_hitting_level != INF)
                        continue;
                    
                    //check if the neighbor is not a keyword node

                    if (!is_keyword(neighbor_id, keyword_nodes)) {

                        int neighbor_activation_level = min_activations[neighbor_id];
                        if (neighbor_activation_level > bfs_level + 1) {
                            F_identifier[curr_node] = 1;
                            continue;
                        }
                    }
                    
                    M[neighbor_id * query_num + bfs_instance] = bfs_level + 1;
                    F_identifier[neighbor_id] = 1;
                }
            }
        }   
    }
}


#undef INF