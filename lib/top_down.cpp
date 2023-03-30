#include <algorithm>
#include <deque>
#include <unordered_set>
#include <vector>
#include <iostream>
#include "top_down.h"
#include "util.h"
#include "graph.h"
#include "Bfs.h"
#define INF 2147483647


void topdown_construct(const CsrGraph* graph, CooGraph** result, const int* C_identifier, const int* M, const int query_num, const int k, const std::vector<std::vector<int>> keyword_nodes, const int* min_activations, const float* node_weights) {
    
    int* costs = (int*) calloc(k, sizeof(int));
    int num_central_graphs = 0;

    for(int central_node = 0; central_node < graph->num_nodes; ++central_node) {

        if (C_identifier[central_node]) {
            
            CooGraph* curr_graph = (CooGraph*) malloc(sizeof(CooGraph));
            curr_graph->num_nodes = 1;
            curr_graph->num_edges = 0;
            curr_graph->row_indices = (int*) calloc(graph->num_nodes, sizeof(int));
            curr_graph->col_indices = (int*) calloc(graph->num_edges, sizeof(int));
            curr_graph->edge_labels = (int*) calloc(graph->num_edges, sizeof(int));

            std::deque<int> frontier {}, next_frontier {};
            std::unordered_set<int> added_nodes {central_node};
            frontier.push_front(central_node);
            
            while (!frontier.empty()) {

                int curr_node = frontier.front();
                frontier.pop_front();
                
                next_frontier = std::deque<int> {};
                int min_activation_level = min_activations[curr_node];

                //scan the neighbors of curr_node
                for(int neighbor = graph->row_offsets[curr_node]; neighbor < graph->row_offsets[curr_node + 1]; ++neighbor) {
                    
                    int neighbor_id = graph->col_indices[neighbor];
                    int edge_label = graph->edge_labels[neighbor];
                    bool added = false;

                    for (int bfs_instance = 0; bfs_instance < query_num; ++bfs_instance) {

                        int curr_hitting_level = M[curr_node * query_num + bfs_instance];
                        int neighbor_hitting_level = M[neighbor_id * query_num + bfs_instance];
                        int neighbor_activation_level = min_activations[neighbor_id];

                        if (is_keyword(curr_node, keyword_nodes) && curr_hitting_level == 1 + std::max(neighbor_activation_level , neighbor_hitting_level)) {
                            
                            curr_graph->row_indices[curr_graph->num_edges] = curr_node;
                            curr_graph->col_indices[curr_graph->num_edges] = neighbor_id;
                            curr_graph->edge_labels[curr_graph->num_edges++] = edge_label;

                            curr_graph->row_indices[curr_graph->num_edges] = neighbor_id;
                            curr_graph->col_indices[curr_graph->num_edges] = curr_node;
                            curr_graph->edge_labels[curr_graph->num_edges++] = edge_label;
                            
                            //check if neighbor in the next frontier
                            if (std::find(next_frontier.begin(), next_frontier.end(), neighbor_id) == next_frontier.end()) {
                                next_frontier.push_front(neighbor_id);
                            }
                            added = true;
                        }

                        else {
                            if (curr_hitting_level == 1 + std::max({neighbor_activation_level, neighbor_hitting_level, min_activation_level - 1})) {
                            
                                curr_graph->row_indices[curr_graph->num_edges] = curr_node;
                                curr_graph->col_indices[curr_graph->num_edges] = neighbor_id;
                                curr_graph->edge_labels[curr_graph->num_edges++] = edge_label;

                                curr_graph->row_indices[curr_graph->num_edges] = neighbor_id;
                                curr_graph->col_indices[curr_graph->num_edges] = curr_node;
                                curr_graph->edge_labels[curr_graph->num_edges++] = edge_label;


                                if (std::find(next_frontier.begin(), next_frontier.end(), neighbor_id) == next_frontier.end()) {
                                    next_frontier.push_back(neighbor_id);
                                }
                                added = true;
                            }
                        }
                    }
                    frontier = next_frontier;
                    if (added) {
                        added_nodes.insert(neighbor_id);
                    }
                }   
            }
            
            curr_graph->row_indices = (int*) realloc(curr_graph->row_indices, curr_graph->num_edges * sizeof(int));
            curr_graph->col_indices = (int*) realloc(curr_graph->col_indices, curr_graph->num_edges * sizeof(int));
            curr_graph->edge_labels = (int*) realloc(curr_graph->edge_labels, curr_graph->num_edges * sizeof(int));
            curr_graph->num_nodes = added_nodes.size();
            if (!curr_graph->row_indices || !curr_graph->col_indices || !curr_graph->edge_labels) {
                freeGraph(curr_graph);
                std::cerr << "Memory allocation  failed at central_node: " << central_node << "\n"; 
                continue;
            }

            level_cover(curr_graph);

            int curr_score = score(curr_graph, central_node, node_weights, M, query_num);

            if (num_central_graphs < k) {
                result[num_central_graphs] = curr_graph;
                costs[num_central_graphs++] = curr_score;
            }
            
        else {
                int* max_cost = std::max_element(costs, costs + k);
                if (curr_score < *max_cost) {
                    int max_cost_index = std::distance(costs, max_cost);
                    freeGraph(result[max_cost_index]);
                    result[max_cost_index] = curr_graph;
                    costs[max_cost_index] = curr_score;
                }

                else {
                    freeGraph(curr_graph);
                }
            }
        }
    }
    free(costs);
}


void level_cover(CooGraph* graph ) {
    //TODO
}

#undef INF