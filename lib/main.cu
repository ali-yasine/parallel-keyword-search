#include <iostream>
#include <unordered_map>
#include <string>
#include <cstring>
#include <fstream>
#include <unistd.h>
#include <sstream>
#include <vector>
#include <unordered_set>
#include <algorithm>

#include "graph.h"
#include "index.h"
#include "pks.h"
#include "util.h"
#include "timer.h"
#include "gpu_util.h"


int main(int argc, char** argv) {
    Timer timer;
    std::vector<std::string> query;
    std::unordered_map<int, string> label_nodes {};

    
    std::cerr << "reading graph...\n";
    
    const char* filename = "data/wikidata.rdf";

    //init variables
    CooGraph* graph_coo = (CooGraph*) malloc(sizeof(CooGraph));
    std::unordered_map<int, string> node_map {};
    std::unordered_map<string, int> node_map_reverse {};
    std::unordered_map<int, string> edge_map {};
    std::unordered_map<string, int> edge_map_reverse {};
    
    int num_nodes = 42868213;
    int num_edges = 193634832;
    
    node_map.reserve(num_nodes);
    node_map_reverse.reserve(num_nodes);
    edge_map.reserve(num_edges);
    edge_map_reverse.reserve(num_edges);

    
    //read graph and convert to CSR format
    startTime(&timer);  
    
    readGraph(filename, graph_coo, &node_map, &node_map_reverse, &edge_map, &edge_map_reverse, &label_nodes, num_nodes, num_edges, true);
    
    stopTime(&timer);
    printElapsedTime(timer, "Read graph time", CYAN);

    std::cerr << "converting to CSR...\033[0m\n";
    CsrGraph* graph = (CsrGraph*) malloc(sizeof(CsrGraph));
    startTime(&timer);

    cooToCSR(graph_coo, graph);
    
    stopTime(&timer);
    printElapsedTime(timer, "Convert to CSR time", CYAN);

    float* node_weights = (float*) malloc(graph->num_nodes * sizeof(float));
    float avg_hops = 0;

    std::cerr << "building index...\n";
    //check if index exists
    startTime(&timer);
    
    if (filename == "data/euler.txt") {
        readGraphIndex("index/euler_index.txt", node_weights, avg_hops, graph->num_nodes);
    }

    else if (access("index/wikidata_index.txt", F_OK) == 0) {
        readGraphIndex("index/wikidata_index.txt", node_weights, avg_hops, graph->num_nodes);
    }
    else {
        getVertexInformativeness(graph, graph_coo, node_weights, avg_hops);
        writeGraphIndex("index/wikidata_index.txt", node_weights, avg_hops, graph->num_nodes);
    }

    stopTime(&timer);

    printElapsedTime(timer, "build index time", CYAN);
    freeGraph(graph_coo);

    CsrGraph *graph_d = createEmptyCsrGPU(num_nodes, num_edges);

    // copy graph to device
    copyCsrGraphToDevice(graph, graph_d);

    //init result and hyperparameters
    int k = 2;
    float alpha = 0.1f;

    int* min_activations = (int*) malloc(sizeof(int) * graph->num_nodes);
    getMinActivations(node_weights, graph->num_nodes, alpha, avg_hops, min_activations);

    int* min_activations_d;
    cudaMalloc((void**) &min_activations_d, sizeof(int) * graph->num_nodes);
    cudaMemcpy(min_activations_d, min_activations, sizeof(int) * graph->num_nodes, cudaMemcpyHostToDevice);

    while (true) {


        std::cerr << "Please enter your query (Enter 'exit' to quit):\n";
        CooGraph** results = (CooGraph**) malloc(sizeof(CooGraph*) * k);
        std::string input;

        std::getline(std::cin, input);
        if (input == "exit") {
            break;
        }

        std::vector<std::string> query {};
        std::stringstream ss(input);

        std::string token;
        while (std::getline(ss, token, ' ')) {
            std::transform(token.begin(), token.end(), token.begin(), ::tolower);
            query.push_back(token);
        }
        

        std::cerr << "getting query vertices...\n";
        //init query vertices
        std::vector<std::unordered_set<int>> keyword_nodes (query.size(), std::unordered_set<int> {});
        startTime(&timer);
        
        getQueryVertices(query, label_nodes, graph->num_nodes, keyword_nodes);

        stopTime(&timer);

        printElapsedTime(timer, "get query vertices time", CYAN);

        bool valid = true;

        for(int keyword = 0; keyword < keyword_nodes.size(); ++keyword) {
            if (keyword_nodes[keyword].size() == 0) {
                std::cerr << "keyword " << query[keyword] << " not found in graph\n";
                valid = false;
            }
        }


        if (!valid) {
            continue;
        }


        //run pks
        startTime(&timer);

        pks(graph, keyword_nodes, results, k, alpha, node_weights, min_activations, avg_hops);
            
        stopTime(&timer);

        printElapsedTime(timer, " total PKS time", GREEN);

        //print results
        for(int i = 0; i < k; ++i) {
            //reset color
            printGraph(results[i], node_map, edge_map, "result.txt");
        }
        std::cerr << "wrote result to result.txt\n";

        for(int i = 0; i < k; ++i) {
            freeGraph(results[i]);
        }

        free(results);

        results = (CooGraph**) malloc(sizeof(CooGraph*) * k);
        std::cerr << "running pks_gpu...\n";

        startTime(&timer);
        
        pks_gpu(graph, graph_d,  keyword_nodes, results, k, alpha, node_weights, min_activations, min_activations_d, avg_hops);

        stopTime(&timer);

        printElapsedTime(timer, " total PKS GPU time", GREEN);
        
        //print results
        for(int i = 0; i < k; ++i) {
            printGraph(results[i], node_map, edge_map, "result_gpu.txt");   
        }
        std::cerr << "wrote result to result_gpu.txt\n";

        for(int i = 0; i < k; ++i) {
            freeGraph(results[i]);
        }

        free(results);
        results = (CooGraph**) malloc(sizeof(CooGraph*) * k);
        std::cerr << "running pks_bitwise...\n";

        startTime(&timer);
        pks_gpu_bitwise(graph, graph_d, keyword_nodes, results, k, alpha, node_weights, min_activations, min_activations_d, avg_hops);

        stopTime(&timer);

        printElapsedTime(timer, " total PKS GPU bitwise time", GREEN);

        //print results
        for(int i = 0; i < k; ++i) {
            printGraph(results[i], node_map, edge_map, "result_bitwise.txt");   
        }

        std::cerr << "wrote result to result_bitwise.txt\n";

        for(int i = 0; i < k; ++i) {
            freeGraph(results[i]);
        }

        free(results);
    }
    free(node_weights);
    free(min_activations);
    cudaFree(min_activations_d);
    cudaFreeGraph(graph_d);
    freeGraph(graph);
    return 0;
}
