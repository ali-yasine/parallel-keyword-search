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

void getVertexInformativeness(const CsrGraph* csr, float* vertex_w) {

        
    //maps (vertex, label) to number of edges of that type incident to that vertex
    std::unordered_map<std::pair<int, int>, int, pair_hash, pair_equal> num_edges_map {};
    float max_w = std::numeric_limits<float>::min();
    float min_w = std::numeric_limits<float>::max();

    for(int i = 0; i < csr->num_edges; ++i) {
        int dst = csr->col_indices[i];
        int label = csr->edge_labels[i];
        
        std::pair<int, int> key {dst, label};
        num_edges_map[key]++;        
    }

    std::unordered_set<int> counted_labels {};
    
    for(int node = 0; node < csr->num_nodes; ++node) {
        
        float total_edges = csr->row_offsets[node + 1] - csr->row_offsets[node];
        float weight = 0;

        for (int edge = csr->row_offsets[node]; edge < csr->row_offsets[node + 1]; ++edge) {
            int label = csr->edge_labels[edge];

            if (counted_labels.find(label) == counted_labels.end()) {
                counted_labels.insert(label);
                std::pair<int, int> key {node, label};
                weight += num_edges_map[key] * log2(1.0f + num_edges_map[key]);
            }
        }
        
        weight /= total_edges;
        max_w = std::max(max_w, weight);
        min_w = std::min(min_w, weight);
        vertex_w[node] = weight;

        counted_labels.clear();
    }
    
    for(int i = 0; i < csr->num_nodes ; ++i) {
        vertex_w[i] = (vertex_w[i] - min_w) / (max_w - min_w);
    }

}

float averageDistanceInGraph(const CsrGraph* graph, int num_samples) {
    
    //get average number of hops needed to reach a vertex from another vertex by sampling
    int n = graph->num_nodes;
    RandomGen rand_gen {0, n - 1};
    int total_hops = 0;
    int sample_count = 0;

    vector<int> distances(n, -1);


    for(int i = 0; i < num_samples; ++i) {

        int src = rand_gen();

        distances[src] = 0;

        //bfs
        std::queue<int> q;
        q.push(src);

        while(!q.empty()) {
            int node = q.front();
            q.pop();

            for(int neighbor = graph->row_offsets[node]; neighbor < graph->row_offsets[node + 1]; ++neighbor) {
                if(distances[graph->col_indices[neighbor]] == -1) {
                    distances[graph->col_indices[neighbor]] = distances[node] + 1;
                    q.push(graph->col_indices[neighbor]);
                }
            }
        }

        for (int dst : distances) {
            if (dst != -1) {
                total_hops += dst;
                sample_count++;
            }
        }
        distances.assign(n, -1);
    }
    
    return (float) total_hops / sample_count;   
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
