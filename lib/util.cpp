#include "util.h"
#include <vector>
#include <string>
#include <unordered_map>
#define INF 2147483647


void getQueryVertices(const std::vector<std::string>& query,
                      const std::unordered_map<int, std::string>& node_map,
                      const int num_nodes,
                      std::vector<std::vector<int>>& query_vertices) {
    query_vertices.resize(query.size());
    
    for (std::size_t i = 0; i < query.size(); ++i) {
        const auto& term = query[i];
        query_vertices[i].clear();
        for (const auto& node_pair : node_map) {
            if (node_pair.first >= 0 && node_pair.first < num_nodes &&
                node_pair.second.find(term) != std::string::npos) {
                query_vertices[i].push_back(node_pair.first);
            }
        }
    }
}


int getActivationLevel(float node_weight, float alpha, float avg_hops) {


    float epsilon = 0.0001; //hyperparameter try tweaking later

    //check if node_weight < alpha
    if (std::fabs(node_weight - alpha) < epsilon) {
        return (int) std::round(avg_hops);
    }

    if (node_weight < alpha) {
        float reward = avg_hops * (alpha - node_weight) / alpha;
        return (int) std::round(avg_hops - reward);
    }

    float penalty = avg_hops * (node_weight - alpha) / (1 - alpha); 

    return (int) std::round(avg_hops + penalty);
}

void identify_central(const num_nodes, int* C_identifier, const int* F_identifier , const  int* M, const int query_num) {
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
        if (F_identifier[i]) {
            frontier[frontier_size++] = i;
        }
    }
    memset(F_identifier, 0, num_nodes * sizeof(int));
}

#undef INF