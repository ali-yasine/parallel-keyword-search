#include <iostream>
#include <unordered_map>
#include <string>
#include <cstring>
#include <fstream>
#include "graph.h"
#include "index.h"
#include "pks.h"
#include "util.h"


int main(int argc, char** argv) {

    std::vector<std::string> query;
    if (argc  < 2) {
        query = {"Euler", "Abigail", "Katharina"};
    }
    else {
        for (int i = 1; i < argc; ++i) {
            query.push_back(argv[i]);
        }
    }

    const char* filename = "data/euler.txt";

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


    //init query vertices
    std::vector<std::vector<int>> keyword_nodes {};

    getQueryVertices(query, node_map, graph->num_nodes, keyword_nodes);
    
    //init result and hyperparameters
    int k = 1;
    float alpha = 0.1f;
    
    CooGraph** results = (CooGraph**) malloc(sizeof(CooGraph*) * k);
    
    //run pks
    pks(graph, keyword_nodes, results, k, alpha);

    //print results
    for(int i = 0; i < k; ++i) {
        std::cout << "\033[1;32m wrote result to result.txt";
        //reset color
        std::cout << "\033[0m";
        printGraph(results[i], node_map, edge_map, "result.txt");
    }

    for(int i = 0; i < k; ++i) {
        freeGraph(results[i]);
    }

    free(results);
    freeGraph(graph_coo);
    freeGraph(graph);

    return 0;
}
