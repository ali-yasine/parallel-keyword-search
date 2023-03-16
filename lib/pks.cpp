#include <iostream>
#include "graph.h"
#include "pks.h"
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