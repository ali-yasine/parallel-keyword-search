#include <vector>
#include <string>
#include <unordered_map>
#include <cmath>
#include <algorithm>
#include <string>
#include <cstring>
#include <cctype>  
#include <limits>
#include "util.h"
#define INF std::numeric_limits<int>::max()


#include <random>



bool isSubstring(std::string haystack, std::string needle) {
    std::transform(haystack.begin(), haystack.end(), haystack.begin(), ::tolower);
    std::transform(needle.begin(), needle.end(), needle.begin(), ::tolower);
    return haystack.find(needle) != std::string::npos;
}

void getQueryVertices(const std::vector<std::string>& query,
                      const std::unordered_map<int, std::string>& node_map,
                      const int num_nodes,
                      std::vector<std::vector<int>>& query_vertices) {
    query_vertices.resize(query.size());
    
    for (std::size_t i = 0; i < query.size(); ++i) {
        const auto& term = query[i];
        query_vertices[i].clear();
        for (const auto& node_pair : node_map) {

            if (node_pair.first >= 0 && node_pair.first < num_nodes && isSubstring(node_pair.second, term)) {
                query_vertices[i].push_back(node_pair.first);
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


void identify_central(const int num_nodes, int* C_identifier, const int* F_identifier , const  int* M, const int query_num) {
    
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
                C_identifier[node] = 1;
        }
    }
}

void enqueue_frontier(const int num_nodes, int* F_identifier, int* frontier, int& frontier_size) {
    
    for (int i = 0; i < num_nodes; ++i) {
        frontier[i] = F_identifier[i];        
        F_identifier[i] = 0;
    }
    frontier_size += num_nodes;
}

bool is_keyword(int node, const std::vector<std::vector<int>>& keyword_nodes) {
    for (int i = 0; i < keyword_nodes.size(); ++i) {
        for (int j = 0; j < keyword_nodes[i].size(); ++j) {
            if (node == keyword_nodes[i][j])
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

    int num_nodes = graph->num_nodes;

    float total_weight = 0;
    int* visited = (int*) calloc(num_nodes, sizeof(int));

    for(int node = 0; node < graph->num_nodes; ++node) {
        if (!visited[node]){
            total_weight += node_weights[graph->row_indices[node]];
            visited[node] = 1;
        }
    }
    free(visited);
    return std::pow(depth, lambda) * total_weight;
}

#undef INF