#include <vector>
#include <string>
#include <unordered_map>
#include <cmath>
#include <algorithm>
#include <string>
#include <cstring>
#include <random>
#include <cctype>  
#include <limits>
#include "util.h"

#define INF 2147483647

bool isSubstring(std::string haystack, std::string needle) {
    return haystack.find(needle) != std::string::npos;
}

void getQueryVertices(const std::vector<std::string>& query,
                      const std::unordered_map<int, std::string>& node_map,
                      const int num_nodes,
                      std::vector<std::unordered_set<int>>& query_vertices) {
    
    for (std::size_t i = 0; i < query.size(); ++i) {
        const auto& term = query[i];
        for (const auto& node_pair : node_map) {
            if (node_pair.first >= 0 && node_pair.first < num_nodes && isSubstring(node_pair.second, term)) {
                query_vertices[i].insert(node_pair.first);
            }
        }
    }
}

int getActivationLevel(const float node_weight, const float alpha, const  float avg_hops) {

    float epsilon = 0.00001; //hyperparameter try tweaking later

    //check if node_weight < alpha
    if (std::abs(node_weight - alpha) < epsilon) {
        return (int) std::round(avg_hops);
    }

    if (node_weight < alpha) {
        float reward = avg_hops * (alpha - node_weight) / alpha;
        return (int) std::round(avg_hops - reward);
    }

    float penalty = avg_hops * (node_weight - alpha) / (1 - alpha); 

    return (int) std::round(avg_hops + penalty);
}

void identify_central(const int num_nodes, bool* C_identifier, const bool* F_identifier , const int* M, const int query_num) {
    
    for (int node = 0; node < num_nodes; ++node) {

        if (F_identifier[node]) {
            bool is_central = true;
            for (int i = 0; i < query_num; ++i) {
                if (M[node * query_num + i] == INF) {
                    is_central = false;
                    break;
                }
            }
            if (is_central)
                C_identifier[node] = true;
        }
    }
}

void enqueue_frontier(const int num_nodes, bool* F_identifier, bool* frontier, int& frontier_size) {
    
    for (int i = 0; i < num_nodes; ++i) {
        frontier[i] = F_identifier[i];        
        F_identifier[i] = false;
    }
    frontier_size += num_nodes;
}

bool is_keyword(int node, const std::vector<std::unordered_set<int>>& keyword_nodes) {
    for (std::size_t i = 0; i < keyword_nodes.size(); ++i) {
        if (keyword_nodes[i].find(node) != keyword_nodes[i].end()) {
            return true;
        }
    }
    return false;
}

void getMinActivations(const float* node_weights, const int num_nodes, const float alpha, const float avg_hops, int* min_activations) {
    for (int i = 0; i < num_nodes; ++i) {
        min_activations[i] = getActivationLevel(node_weights[i], alpha, avg_hops);
    }
}

float score(const CooGraph* graph, const int central_node, const float* node_weights, const int* M, const int query_num, const float lambda) {

    int depth = 0;
    for (int i = 0; i < query_num; ++i) {
        if (M[central_node * query_num + i] > depth) {
            depth = M[central_node * query_num + i];
        }
    }

    float total_weight = 0;
    std::unordered_set<int> visitedSet {};
    
    for(int edge = 0; edge < graph->num_edges; ++edge) {
        int node = graph->col_indices[edge];

        if (visitedSet.find(node) == visitedSet.end()) {
            total_weight += node_weights[node];
            visitedSet.insert(node);
        }
    }
    
    return powf((float) depth, lambda) * total_weight;
}

void dequeue_frontier(bool* frontier, int& frontier_size, const int num_nodes) {
    for (int i = 0; i < num_nodes; ++i) {
        frontier[i] = 0;
    }
    frontier_size = 0;
}

bool check_terminate(const bool* C_identifier, const int num_nodes, const int k) {
    
    int count = 0;
    
    for (int i = 0; i < num_nodes; ++i) {
        if (C_identifier[i])
            count++;
    }

    return count >= k;

}


#undef INF