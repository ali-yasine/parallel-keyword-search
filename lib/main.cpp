#include <iostream>
#include "graph.h"
#include "index.h"
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


    //init variables
    CooGraph* graph_coo = (CooGraph*) malloc(sizeof(CooGraph));
    std::unordered_map<int, string> node_map {};
    std::unordered_map<string, int> node_map_reverse {};
    std::unordered_map<int, string> edge_map {};
    std::unordered_map<string, int> edge_map_reverse {};

    //read graph and convert to CSR format
    readGraph(filename, graph_coo, &node_map, &node_map_reverse, &edge_map, &edge_map_reverse);

    CsrGraph* graph = (CsrGraph*) malloc(sizeof(CsrGraph));

    cooToCSR(graph_coo, graph);


    //parse query
    int query_num = (argc > 2) ? atoi(argv[2]) : 3;

    std::vector<std::string> query {"Euler", "Thesis", "Title"};
    std::vector<std::vector<int>> keyword_nodes {};

    getQueryVertices(query, node_map, graph->num_nodes, keyword_nodes);
    
    //init result and hyperparameters
    CsrGraph** results = (CsrGraph**) malloc(sizeof(CsrGraph*));
    
    int k = 5;
    float alpha = 0.01;
    
    //run pks
    pks(graph, keyword_nodes, results, k, alpha);

    
    freeGraph(graph_coo);
    freeGraph(graph);
    return 0;
}
