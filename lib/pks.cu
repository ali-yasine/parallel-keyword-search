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
#include "timer.h"
#include "top_down.h"

#define INF 2147483647

void pks(const CsrGraph* graph, const std::vector<std::unordered_set<int>>& keyword_nodes, 
        CooGraph** result, const int k, const float alpha, const float* node_weights, const int* min_activations, const float avg_hops) {
    
    
    std::cerr << "starting pks\n";
    Timer timer;
    int query_num = keyword_nodes.size();
    int num_nodes = graph->num_nodes;
    
    //initialize F,C and M the node-keyword matrix
    bool* F_identifier = (bool*) calloc(num_nodes, sizeof(bool));
    bool* C_identifier = (bool*) calloc(num_nodes, sizeof(bool));
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
        for (int node : keyword_nodes[i]) {
            F_identifier[node] = true;
            M[node * query_num + i] = 0;
        }
    }
    
    int BFS_level = 0;
    bool terminate = false;
    
    bool* frontier = (bool*) calloc(num_nodes, sizeof(bool));
    
    if (!frontier) {
        std::cerr << "cannot allocate frontier memory\n";
        exit(1);
    }
    
    int frontier_size = 0;
    //print F_identifier
    
    bool* is_keyword_arr = (bool*) calloc(num_nodes, sizeof(bool));

    for (int i = 0; i < query_num; ++i) {
        for (int node : keyword_nodes[i]) {
            is_keyword_arr[node] = true;
        }
    }

    startTime(&timer);
    while (!terminate) {
        enqueue_frontier(num_nodes, F_identifier, frontier,  frontier_size);

        expand(graph, frontier,  F_identifier, M, C_identifier, min_activations, BFS_level, alpha, avg_hops, is_keyword_arr, query_num);

        identify_central(num_nodes, C_identifier, F_identifier, M, query_num);

        BFS_level++;

        dequeue_frontier(frontier, frontier_size, num_nodes);

        terminate = check_terminate(C_identifier, num_nodes, k);
    }

    stopTime(&timer);
    printElapsedTime(timer, "expansion cpu time: ");
    
    std::cerr << "start topdown construct\n";
    topdown_construct(graph, result, C_identifier, M, query_num, k, keyword_nodes, min_activations, node_weights);
    
    free(F_identifier);
    free(C_identifier);
    free(M);
    free(frontier);
}

void expand(const CsrGraph* graph, const bool* frontier, bool* F_identifier, int* M, bool* C_identifier, const int* min_activations, int bfs_level, const float alpha, const float avg_hops,  bool* keyword_nodes, int query_num) {
                
    for(int curr_node = 0; curr_node < graph->num_nodes; ++curr_node) {

        if (frontier[curr_node]) {
            
            if (C_identifier[curr_node]) 
                continue;

            int min_activation_level = min_activations[curr_node];

            if (min_activation_level > bfs_level) {
                F_identifier[curr_node] = true;
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

                    if (!keyword_nodes[neighbor_id]) {
                        
                        int neighbor_activation_level = min_activations[neighbor_id];
                        if (neighbor_activation_level > bfs_level + 1) {
                            F_identifier[curr_node] = true;
                            continue;
                        }
                    }
                    M[neighbor_id * query_num + bfs_instance] = bfs_level + 1;
                    F_identifier[neighbor_id] = true;
                }
            }
        }   
    }
}

#undef INF