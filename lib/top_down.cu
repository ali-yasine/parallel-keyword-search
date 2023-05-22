#include <algorithm>
#include <deque>
#include <unordered_set>
#include <vector>
#include <queue>

#include <iostream>
#include "top_down.h"
#include "util.h"
#include "graph.h"
#define INF 2147483647
#define ull unsigned long long


struct Compare_graphs {
    bool operator()(const std::pair<CooGraph*, int>& p1, const std::pair<CooGraph*, int>& p2) {
        return p1.second < p2.second;
    }
};


void topdown_construct(const CsrGraph* graph, CooGraph** result, const bool* C_identifier, const int* M, const int query_num, const int k, const std::vector<std::unordered_set<int>> keyword_nodes, const int* min_activations, const float* node_weights) {
    
    int* costs = (int*) calloc(k, sizeof(int));
    int* is_next_frontier = (int*) malloc(graph->num_nodes * sizeof(int));

    std::priority_queue<std::pair<CooGraph*, int>, std::vector<std::pair<CooGraph*, int>>, Compare_graphs> heap {};

    for(int central_node = 0; central_node < graph->num_nodes; ++central_node) {
        
        if (C_identifier[central_node]) {

            memset(is_next_frontier, 0, graph->num_nodes * sizeof(int));
            
            CooGraph* curr_graph = (CooGraph*) malloc(sizeof(CooGraph));
            curr_graph->num_nodes = 1;
            curr_graph->num_edges = 0;
            curr_graph->row_indices = (int*) malloc(graph->num_edges * sizeof(int));
            curr_graph->col_indices = (int*) malloc(graph->num_edges * sizeof(int));
            curr_graph->edge_labels = (int*) malloc(graph->num_edges * sizeof(int));

            std::deque<int> frontier {}, next_frontier {};
            std::unordered_set<int> added_nodes {central_node};
            frontier.push_front(central_node);
            
            while (!frontier.empty()) {

                int curr_node = frontier.front();
                frontier.pop_front();
                next_frontier.clear();
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
                            if (!is_next_frontier[neighbor_id]) {
                                next_frontier.push_front(neighbor_id);
                                is_next_frontier[neighbor_id] = true;
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


                                if (!is_next_frontier[neighbor_id]) {
                                    
                                    is_next_frontier[neighbor_id] = true;
                                    next_frontier.push_back(neighbor_id);
                                }
                                added = true;
                            }
                        }

                        if (added) {
                            added_nodes.insert(neighbor_id);
                            frontier = next_frontier;
                            break;
                        }
                    }
                }   
            }
            
            curr_graph->row_indices = (int*) realloc(curr_graph->row_indices, curr_graph->num_edges * sizeof(int));
            curr_graph->col_indices = (int*) realloc(curr_graph->col_indices, curr_graph->num_edges * sizeof(int));
            curr_graph->edge_labels = (int*) realloc(curr_graph->edge_labels, curr_graph->num_edges * sizeof(int));
            curr_graph->num_nodes = added_nodes.size();
            
            if (!curr_graph->row_indices || !curr_graph->col_indices || !curr_graph->edge_labels) {
                std::cerr << "Error: Memory allocation failed realloc top_down\n";
                freeGraph(curr_graph);
                continue;
            }

            level_cover(curr_graph, keyword_nodes, central_node);

            int curr_score = score(curr_graph, central_node, node_weights, M, query_num);

            if (heap.size() < k) {
                heap.push(std::make_pair(curr_graph, curr_score));
            }
            else {
                if (curr_score < heap.top().second) {
                    freeGraph(heap.top().first);
                    heap.pop();
                    heap.push(std::make_pair(curr_graph, curr_score));
                }
                else {
                    freeGraph(curr_graph);
                }
            }
        }
    }
    free(is_next_frontier);

    for(int i = k - 1; i >= 0; --i) {
        result[i] = heap.top().first;
        heap.pop();
    }
    free(costs);
}


void topdown_construct(const CsrGraph* graph, CooGraph** result, const ull* C_identifier, const int* M, const int query_num, const int k, const std::vector<std::unordered_set<int>> keyword_nodes, const int* min_activations, const float* node_weights) {
    
    int* costs = (int*) calloc(k, sizeof(int));
    int* is_next_frontier = (int*) malloc(graph->num_nodes * sizeof(int));

    std::priority_queue<std::pair<CooGraph*, int>, std::vector<std::pair<CooGraph*, int>>, Compare_graphs> heap {};

    for(int central_node = 0; central_node < graph->num_nodes; ++central_node) {
        
        if (C_identifier[central_node / 64] & (1ULL << (central_node % 64))) {

            memset(is_next_frontier, 0, graph->num_nodes * sizeof(int));
            
            CooGraph* curr_graph = (CooGraph*) malloc(sizeof(CooGraph));
            curr_graph->num_nodes = 1;
            curr_graph->num_edges = 0;
            curr_graph->row_indices = (int*) malloc(graph->num_edges * sizeof(int));
            curr_graph->col_indices = (int*) malloc(graph->num_edges * sizeof(int));
            curr_graph->edge_labels = (int*) malloc(graph->num_edges * sizeof(int));

            std::deque<int> frontier {}, next_frontier {};
            std::unordered_set<int> added_nodes {central_node};
            frontier.push_front(central_node);
            
            while (!frontier.empty()) {

                int curr_node = frontier.front();
                frontier.pop_front();
                next_frontier.clear();
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
                            if (!is_next_frontier[neighbor_id]) {
                                next_frontier.push_front(neighbor_id);
                                is_next_frontier[neighbor_id] = true;
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


                                if (!is_next_frontier[neighbor_id]) {
                                    
                                    is_next_frontier[neighbor_id] = true;
                                    next_frontier.push_back(neighbor_id);
                                }
                                added = true;
                            }
                        }

                        if (added) {
                            added_nodes.insert(neighbor_id);
                            frontier = next_frontier;
                            break;
                        }
                    }
                }   
            }
            
            curr_graph->row_indices = (int*) realloc(curr_graph->row_indices, curr_graph->num_edges * sizeof(int));
            curr_graph->col_indices = (int*) realloc(curr_graph->col_indices, curr_graph->num_edges * sizeof(int));
            curr_graph->edge_labels = (int*) realloc(curr_graph->edge_labels, curr_graph->num_edges * sizeof(int));
            curr_graph->num_nodes = added_nodes.size();
            
            if (!curr_graph->row_indices || !curr_graph->col_indices || !curr_graph->edge_labels) {
                std::cerr << "Error: Memory allocation failed realloc top_down\n";
                freeGraph(curr_graph);
                continue;
            }

            level_cover(curr_graph, keyword_nodes, central_node);

            int curr_score = score(curr_graph, central_node, node_weights, M, query_num);

            if (heap.size() < k) {
                heap.push(std::make_pair(curr_graph, curr_score));
            }
            else {
                if (curr_score < heap.top().second) {
                    freeGraph(heap.top().first);
                    heap.pop();
                    heap.push(std::make_pair(curr_graph, curr_score));
                }
                else {
                    freeGraph(curr_graph);
                }
            }
        }
    }
    free(is_next_frontier);

    for(int i = k - 1; i >= 0; --i) {
        result[i] = heap.top().first;
        heap.pop();
    }
    free(costs);
}

void level_cover(CooGraph*& graph, const std::vector<std::unordered_set<int>> keyword_nodes, const int central_node) {
    std::unordered_map<int, int> keyword_count {};
    std::unordered_set<int> visited {};
    int max_count = 0;

    CooGraph* result = (CooGraph*) malloc(sizeof(CooGraph));
    result->row_indices = (int*) malloc(graph->num_edges * sizeof(int));
    result->col_indices = (int*) malloc(graph->num_edges * sizeof(int));
    result->edge_labels = (int*) malloc(graph->num_edges * sizeof(int));
    result->num_edges = 0;
    result->num_nodes = 0;

    for(int edge = 0; edge < graph->num_edges; ++edge) {
        int src = graph->row_indices[edge];
        if (visited.find(src) == visited.end()) {
            for(int keyword = 0; keyword < keyword_nodes.size(); ++keyword) {
                if (keyword_nodes[keyword].find(src) != keyword_nodes[keyword].end())  {
                    keyword_count[src]++;
                    if (keyword_count[src] > max_count) 
                        max_count = keyword_count[src];
                }
            }
            visited.insert(src);
        }
    }
    visited.clear();

    std::unordered_set<int> cover_nodes {};

    std::vector<std::unordered_set<int>> levels(max_count + 1, std::unordered_set<int> {});
    for (auto it = keyword_count.begin(); it != keyword_count.end(); ++it) {
        if (it->first != central_node) 
            levels[it->second].insert(it->first);
        else
            levels[max_count].insert(it->first);
    }

    bool* covered = (bool*) calloc(keyword_nodes.size(), sizeof(bool));

    for(int level = max_count; level > 0; --level) {
        for (auto it = levels[level].begin(); it != levels[level].end(); ++it) {
            cover_nodes.insert(*it);
            for(int keyword = 0; keyword < keyword_nodes.size(); ++keyword) {
                if (keyword_nodes[keyword].find(*it) != keyword_nodes[keyword].end()){
                    if (!covered[keyword]) {
                        covered[keyword] = true;
                        break;
                    }
                }
            }
        }
        
        //if all keywords are covered, stop
        if (std::all_of(covered, covered + keyword_nodes.size(), [](bool b) {return b;})) {
            break;
        }
    }
    
    free(covered);

    result->num_nodes = cover_nodes.size();
    //prune levels that are not needed
    for (int edge = 0; edge < graph->num_edges; ++edge) {
        int src = graph->row_indices[edge];
        int dst = graph->col_indices[edge];
        
        if (cover_nodes.find(src) != cover_nodes.end() && cover_nodes.find(dst) != cover_nodes.end()) {
            result->row_indices[result->num_edges] = src;
            result->col_indices[result->num_edges] = dst;
            result->edge_labels[result->num_edges++] = graph->edge_labels[edge];
        }
    }
    
        
    result->row_indices = (int*) realloc(result->row_indices, result->num_edges * sizeof(int));
    result->col_indices = (int*) realloc(result->col_indices, result->num_edges * sizeof(int));
    result->edge_labels = (int*) realloc(result->edge_labels, result->num_edges * sizeof(int));

    if (!result->row_indices || !result->col_indices || !result->edge_labels) {
        freeGraph(result);
        return;
    }

    freeGraph(graph);
    graph = result;
}

#undef INF