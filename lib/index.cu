#include <unordered_map>
#include <unordered_set>
#include <vector>
#include <cmath>
#include <queue>
#include <algorithm>
#include <iostream>
#include <fstream>

#include "graph.h"
#include "index.h"
#include "util.h"

using std::vector;  
using std::unordered_map;

struct pair_hash {
    template <class T1, class T2>
    std::size_t operator () (const std::pair<T1, T2>& p) const {
        auto h1 = std::hash<T1>{}(p.first);
        auto h2 = std::hash<T2>{}(p.second);
        return h1 ^ h2;
    }
};

struct pair_equal {
    template <class T1, class T2>
    bool operator () (const std::pair<T1, T2>& lhs, const std::pair<T1, T2>& rhs) const {
        return lhs.first == rhs.first && lhs.second == rhs.second;
    }
};

void getVertexInformativeness(const CsrGraph* csr, const CooGraph* coo,  float* vertex_w, float& avg_hops) {
    std::cerr << "Calculating vertex informativeness...\n";
    float max_w = std::numeric_limits<float>::min();
    float min_w = std::numeric_limits<float>::max();

    avg_hops = averageDistanceInGraph(csr);

    std::vector<std::unordered_map<int, int>> incoming_label_counts(csr->num_nodes, unordered_map<int, int> {});
    
    for(int edge = 0; edge < coo->num_edges; ++edge) {
        int dst = coo->col_indices[edge];
        int label = coo->edge_labels[edge];
        ++incoming_label_counts[dst][label];
    }

    for (int node = 0; node < csr->num_nodes; ++node) {
        const auto& label_counts = incoming_label_counts[node];
        int total_count = 0;
        float informativeness = 0.0f;

        for (const auto& [label, count] : label_counts) {
            total_count += count;
            informativeness += count * std::log2(1.0f + count);
        }
        if (total_count > 0) {
            informativeness /= total_count;
        }
        else {
            informativeness = 0.0f;
        }
        vertex_w[node] = informativeness;

        //update max and min
        min_w = std::min(min_w, informativeness);
        max_w = std::max(max_w, informativeness);
    }
    float range = max_w - min_w;
    for (int node = 0; node < csr->num_nodes; ++node) {
        vertex_w[node] = (vertex_w[node] - min_w) / range;
    }
}

int bfs(const CsrGraph* graph, const int src, const int dst) {
    std::vector<bool> visited(graph->num_nodes, false);
    std::queue<std::pair<int, int>> q {};
    q.push({src, 0});
    visited[src] = true;

    while (!q.empty()) {
        auto [node, distance] = q.front();
        q.pop();
        if (node == dst) {
            return distance;
        }
        
        for (int edge = graph->row_offsets[node]; edge < graph->row_offsets[node + 1]; ++edge) {
            int neighbor = graph->col_indices[edge];
            if (!visited[neighbor]) {
                q.push({neighbor, distance + 1});
                visited[neighbor] = true;
            }
        }
    }

    return -1;
}
float averageDistanceInGraph(const CsrGraph* graph, int num_samples) {
    
    //get average number of hops needed to reach a vertex from another vertex by sampling
    int n = graph->num_nodes;
    RandomGen rand_gen {0, n - 1};
    int total_distance = 0;

    for(int i = 0; i < num_samples; ++i) {
        
        int src = rand_gen();
        int dst = rand_gen();
        int distance = bfs(graph, src, dst);

        if (distance == -1) {
            --i;
            continue;
        }

        total_distance += distance;
    }

    return static_cast<float>(total_distance) / num_samples;
}

void writeGraphIndex(const char* filename, float* vertex_w, float avg_hops, int graph_size) {
    FILE* fp = fopen(filename, "w");
    fprintf(fp, "%lf\n", avg_hops);
    
    for(int i = 0; i < graph_size; ++i) {
        fprintf(fp, "%d: %f \n", i, vertex_w[i]);
    }

    fclose(fp);
}

void readGraphIndex(const char* filename, float* vertex_w, float& avg_hops, int graph_size) {
    FILE* fp = fopen(filename, "r");
    fscanf(fp, "%f\n", &avg_hops);
    int temp;
    for(int i = 0; i < graph_size; ++i) {
        fscanf(fp, "%d: %f ", &temp, &vertex_w[i]);
    }
    fclose(fp);
}
