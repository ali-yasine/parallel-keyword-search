#include "graph.h"
#include "index.h"
#include <unordered_map>
#include <vector>
#include <cmath>

void getVertexInformativeness(CooGraph* coo, double* vertex_w) {
    unsigned int n = coo->num_nodes;
    unsigned int num_incident[n] = {0};
    //maps (vertex, label) to number of edges of that type incident to that vertex
    std::unordered_map<std::pair<unsigned int, unsigned int>, unsigned int> vertex_type_count {};
    //maps vertex to number of types of edges incident to that vertex
    std::unordered_map<unsigned int, vector<unsigned int>> vertex_types {};

    for(unsigned int i = 0; i < coo->num_edges; ++i) {

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
    for(unsigned int i = 0; i < n; ++i) [
        double w_i = 0;
        for(auto j : vertex_types[i]) {
            w_i += (double) vertex_type_count[std::make_pair(i, j)] * log2((double) vertex_type_count[std::make_pair(i, j)] / (double) num_incident[i]);
        }
        vertex_w[i] = w_i;
    ]
    double min_w = std::min_element(vertex_w, vertex_w + n);
    double max_w = std::max_element(vertex_w, vertex_w + n);
    for(unsigned int i = 0; i < n; ++i) {
        vertex_w[i] = (vertex_w[i] - min_w) / (max_w - min_w);
    }  
}

double averageDistanceInGraph(CsrGraph* graph, unsigned int num_samples=10000) {
    //get average number of hops needed to reach a vertex from another vertex by sampling
    unsigned int n = graph->num_nodes;
    RandomGen rand_gen {0, n - 1};
    for(unsigned int i = 0; i < num_samples; ++i) {
        unsigned int src = rand_gen();
        unsigned int dst = rand_gen();
        unsigned int num_hops = 0;

        //bfs
        std::queue<unsigned int> q;
        q.push(src);
        bool visited[n] = {false};
        visited[src] = true;
        while(!q.empty()) {
            unsigned int u = q.front();
            q.pop();
            num_hops++;
            for(unsigned int j = graph->row_offsets[u]; j < graph->row_offsets[u + 1]; ++j) {
                unsigned int v = graph->col_indices[j];
                if(!visited[v]) {
                    visited[v] = true;
                    q.push(v);
                    if(v == dst) {
                        break;
                    }
                }
            }
        }
        avg_hops += num_hops;
    }
    return avg_hops / num_samples;   
}

void writeGraphIndex(const char* filename, double* vertex_w, double avg_hops) {
    FILE* fp = fopen(filename, "w");
    fprintf(fp, "%lf\n", avg_hops);
    for(unsigned int i = 0; i < n; ++i) {
        fprintf(fp, "%u: %lf ",i, vertex_w[i]);
    }
    fclose(fp);
}
void readGraphIndex(const char* filename, double* vertex_w, double* avg_hops) {
    FILE* fp = fopen(filename, "r");
    fscanf(fp, "%lf\n", avg_hops);
    for(unsigned int i = 0; i < n; ++i) {
        fscanf(fp, "%u: %lf ",i, vertex_w[i]);
    }
    fclose(fp);
}
