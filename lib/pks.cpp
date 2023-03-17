#include <iostream>
#include "graph.h"
#include "pks.h"
#include <cmath>
#include "index.h"

void pks(const CsrGraph* graph, const int* query,const int query_num, CsrGraph** result, const int k, const float alpha, const char* filename)  {

    float* vertex_w = (float*) calloc(graph->num_nodes, sizeof(float));
    float avg_hops = 0;

    std::cout << "pks\n";


    if (filename) 
        readGraphIndex(filename, vertex_w, avg_hops, graph->num_nodes);
    else {
        getVertexInformativeness(graph, vertex_w);
        avg_hops = averageDistanceInGraph(graph, 1000);
        writeGraphIndex("index/graph.txt", vertex_w, avg_hops, graph->num_nodes);
    }
    std::cout << "avg_hops: " << avg_hops << std::endl;
    for(int i = 0; i < query_num; ++i) {
        std::cout << "query: " << query[i] << std::endl;
    }
    for(int i = 0; i < graph->num_nodes; ++i) {
        std::cout << "vertex_w: " << vertex_w[i] << std::endl;
    }

}

void expand(CsrGraph* graph, int* F_identifier, int* M, int* C_identifier, float* node_weight, int level, int alpha, float avg_hops) {
    for(int i = 0; i < graph->num_nodes; ++i) {
        if (F_identifier[i]) {
            
            if (C_identifier[i] ) 
                continue;

            int min_activation_level = getActivationLevel(node_weight[i], alpha, avg_hops);

            if (min_activation_level > level) {
                F_identifier[i] = 1;
                continue;
            }

            for(;;) {}
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