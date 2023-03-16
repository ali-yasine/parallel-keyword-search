#include "graph.h"
#include "index.h"
#include <unordered_map>
#include <vector>
#include <cmath>
#include <queue>
#include <algorithm>
#include <iostream>

#include "randomGen.h"
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

void getVertexInformativeness(const CsrGraph* coo, float* vertex_w) {
    int n = coo->num_nodes;
    int num_incident[n] = {0};
    //maps (vertex, label) to number of edges of that type incident to that vertex
    std::unordered_map<std::pair<int, int>, int, pair_hash, pair_equal> vertex_type_count {};
    //maps vertex to number of types of edges incident to that vertex
    std::unordered_map<int, vector<int>> vertex_types {};

    for(int i = 0; i < coo->num_edges; ++i) {

        num_incident[coo->col_indices[i]]++;

        if(vertex_type_count.count(std::make_pair(coo->col_indices[i], coo->edge_labels[i]))) {
            vertex_type_count[std::make_pair(coo->col_indices[i], coo->edge_labels[i])] = 1;
        }
        else{ 
            vertex_type_count[std::make_pair(coo->col_indices[i], coo->edge_labels[i])]++;
        }

        if(vertex_types.count(coo->col_indices[i])) {
            vertex_types[coo->col_indices[i]].push_back(coo->edge_labels[i]);
        }
        else {
            vertex_types[coo->col_indices[i]] = {coo->edge_labels[i]};
        }
    }

    for(int i = 0; i < n; ++i) {

        float w_i = 0;
        
        for(auto j : vertex_types[i]) {
            w_i += (float) vertex_type_count[std::make_pair(i, j)] * log2((float) vertex_type_count[std::make_pair(i, j)] / (float) num_incident[i]);
        }
        vertex_w[i] = w_i;
    }
    
    float min_w = *std::min_element(vertex_w, vertex_w + n);
    float max_w = *std::max_element(vertex_w, vertex_w + n);
    for(int i = 0; i < n; ++i) {
        vertex_w[i] = (vertex_w[i] - min_w) / (max_w - min_w);
    }
}

float averageDistanceInGraph(const CsrGraph* graph, int num_samples=10000) {
    //get average number of hops needed to reach a vertex from another vertex by sampling
    int n = graph->num_nodes;
    RandomGen rand_gen {0, n - 1};
    float total_hops = 0;

    for(int i = 0; i < num_samples; ++i) {
        int src = rand_gen();
        int dst = rand_gen();
        int num_hops = 0;

        //bfs
        std::queue<int> q;
        q.push(src);
        bool visited[n] = {false};
        visited[src] = true;
        while(!q.empty()) {
            int u = q.front();
            q.pop();
            num_hops++;
            for(int j = graph->row_offsets[u]; j < graph->row_offsets[u + 1]; ++j) {
                int v = graph->col_indices[j];
                if(!visited[v]) {
                    visited[v] = true;
                    q.push(v);
                    if(v == dst) {
                        break;
                    }
                }
            }
        }
        total_hops += num_hops;
    }
    return total_hops / num_samples;   
}

void writeGraphIndex(const char* filename, float* vertex_w, float avg_hops, int graph_size) {
    FILE* fp = fopen(filename, "w");
    fprintf(fp, "%lf\n", avg_hops);
    for(int i = 0; i < graph_size; ++i) {
        fprintf(fp, "%d: %f ", i, vertex_w[i]);
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
