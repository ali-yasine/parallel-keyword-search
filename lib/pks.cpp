#include <iostream>
#include <cmath>
#include "graph.h"
#include "pks.h"
#include "util.h"
#include "index.h"

#define INF 2147483647


void pks(const CsrGraph* graph, const std::vector<std::vector<int>> keyword_nodes, 
        CsrGraph** result, const int k, const float alpha, 
        const char* filename) {

    int query_num = keyword_nodes.size();
    int num_nodes = graph->num_nodes;
    float* vertex_w = (float*) calloc(num_nodes, sizeof(float));
    float avg_hops = 0;

    if (filename) 
        readGraphIndex(filename, vertex_w, avg_hops, num_nodes);
    else {
        getVertexInformativeness(graph, vertex_w);
        avg_hops = averageDistanceInGraph(graph, 1000);
        writeGraphIndex("index/graph.txt", vertex_w, avg_hops, num_nodes);
    }

    //initialize F,C and M the node-keyword matrix
    int* F_identifier = (int*) calloc(num_nodes, sizeof(int));
    int* C_identifier = (int*) calloc(num_nodes, sizeof(int));
    int* M = (int*) malloc(num_nodes * query_num, sizeof(int)); 
    memset(M, INF, num_nodes * query_num * sizeof(int));

    //initialize BFS instances
    Bfs_instance bfs_instances[query_num];

    for (int i = 0; i < query_num; ++i) {
        bfs_instances[i].init();
    }

    //put every query vertex into BFS instances
    for (int i = 0; i < query_num; ++i) {
        for (int j = 0; j < keyword_nodes[i].size(); ++j) {
            bfs_instances[i].add(keyword_nodes[i][j]);
            F_identifier[keyword_nodes[i][j]] = 1;

            M[j * num_nodes + keyword_nodes[j][i]] = 0;
        }
    }

    int BFS_level = 0;
    bool terminate = false;
    
    int* frontier = (int*) calloc(num_nodes * sizeof(int));
    int frontier_size = 0;

    while (!terminate) {

        enqueue_frontier(num_nodes frontier, F_identifier, frontier_size);

        expand(graph, F_identifier, M, C_identifier, vertex_w, BFS_level, alpha, avg_hops, keyword_nodes, query_num);

        identify_central(num_nodes, C_identifier, F_identifier, M, query_num);

        BFS_level++;

        memset(frontier, 0, num_nodes * sizeof(int));
        frontier_size = 0;

        if (std::sum(C_identifier) >= k)
            terminate = true;       
    }
    //TODO: construct the result graph

    topdown_construct(graph, result, C_identifier, M, query_num);


    free(F_identifier);
    free(C_identifier);
    free(M);
    free(frontier);
    free(vertex_w);

}

void expand(CsrGraph* graph, const int* frontier, int* F_identifier, int* M, int* C_identifier, float* node_weight, int bfs_level, int alpha, float avg_hops, const std::vector<std::vector<int>> keyword_nodes, int query_num) {
    for(int curr_node = 0; curr_node < graph->num_nodes; ++curr_node) {

        if (frontier[curr_node]) {
            
            if (C_identifier[curr_node]) 
                continue;

            int min_activation_level = getActivationLevel(node_weight[curr_node], alpha, avg_hops);

            if (min_activation_level > bfs_level) {
                F_identifier[curr_node] = 1;
                continue;
            }

            for(int bfs_instance = 0; bfs_instance < query_num; ++bfs_instance) {
                int hitting_level = M[curr_node * query_num + bfs_instance];

                if (hitting_level > bfs_level)
                    continue;
                
                for (int neighbor = graph->row_offsets[curr_node]; neighbor < graph->row_offsets[curr_node + 1]; ++neighbor) {

                    int neighbor_id = graph->column_indices[neighbor];

                    int neighbor_hitting_level = M[neighbor_id * query_num + bfs_instance];

                    if (neighbor_hitting_level != INF)
                        continue;
                    
                    //check if the neighbor is not a keyword node
                    bool is_keyword = false;
                    for (int keyword = 0; keyword < keyword_nodes[bfs_instance].size(); ++keyword) {
                        if (neighbor_id == keyword_nodes[bfs_instance][keyword]) {
                            is_keyword = true;
                            break;
                        }
                    }
                    if (!is_keyword) {
                        int neighbor_activation_level = getActivationLevel(node_weight[neighbor_id], alpha, avg_hops);
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