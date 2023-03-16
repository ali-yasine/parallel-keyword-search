#include <iostream>
#include "graph.h"
#include "pks.h"
#include <unordered_map>
#include <string>
#include <cstring>
#include <fstream>

int main(int argc, char** argv) {
    
    char filename[100];
    if (argc > 1) {
        strcpy(filename, argv[1]);
    } else {
        strcpy(filename, "data/euler.txt");
    }

    CooGraph* graph_coo = (CooGraph*) malloc(sizeof(CooGraph));
    std::unordered_map<int, string> node_map {};
    std::unordered_map<string, int> node_map_reverse {};
    std::unordered_map<int, string> edge_map {};
    std::unordered_map<string, int> edge_map_reverse {};

    readGraph(filename, graph_coo, &node_map, &node_map_reverse, &edge_map, &edge_map_reverse);

    CsrGraph* graph = (CsrGraph*) malloc(sizeof(CsrGraph));

    cooToCSR(graph_coo, graph);

    int querySize = (argc > 2) ? atoi(argv[2]) : 5;

    int query[querySize];
    for (int i = 0; i < querySize; ++i) {
        query[i] = rand() % graph_coo->num_nodes;
    }
    query[0] = 0;

    CsrGraph** results = (CsrGraph**) malloc(sizeof(CsrGraph*));
    
    int k = 5;
    float alpha = 0.5;
    pks(graph, query, querySize, results, k, alpha);

    freeGraph(graph_coo);
    freeGraph(graph);
    return 0;
}
