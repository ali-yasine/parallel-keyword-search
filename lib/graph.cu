#include <fstream>
#include <iostream>
#include <sstream>
#include <wchar.h>
#include <locale.h>
#include <algorithm>
#include <string>
#include <vector>

#include <unordered_map>
#include "graph.h"

using std::string;
using std::fstream;
using std::unordered_map;
using std::stringstream;


void cooToCSR(const CooGraph* coo, CsrGraph* graph) {

    // Initialize fields
    graph->num_nodes = coo->num_nodes;
    graph->num_edges = coo->num_edges;
    graph->row_offsets = (int*) calloc((coo->num_nodes + 1),sizeof(int));
    graph->col_indices = (int*) calloc(coo->num_edges, sizeof(int) );
    graph->edge_labels = (int*) calloc(coo->num_edges, sizeof(int));

    //histogram rows
    for(int i = 0; i < coo->num_edges; ++i) {
        graph->row_offsets[coo->row_indices[i]]++;
    }
    
    
    //prefix sum row offsets
    int sumBeforeNextRow = 0;
    for(int row = 0; row < graph->num_nodes; ++row) {
        int sumBeforeRow = sumBeforeNextRow;
        sumBeforeNextRow += graph->row_offsets[row];
        graph->row_offsets[row] = sumBeforeRow;
    }
    graph->row_offsets[graph->num_nodes] = sumBeforeNextRow;

    //Bin the edges
    for (int i = 0; i < coo->num_edges; ++i) {
        int row = coo->row_indices[i];
        int j = graph->row_offsets[row]++;
        graph->col_indices[j] = coo->col_indices[i];
        graph->edge_labels[j] = coo->edge_labels[i];
    }

    //Restore row offsets
    for (int row = graph->num_nodes; row > 0; --row) {
        graph->row_offsets[row] = graph->row_offsets[row - 1];
    }

    graph->row_offsets[0] = 0;

}

void writeCooToFile(const CooGraph* graph, const char* filename) {
    std::ofstream file(filename);

    file << graph->num_nodes << " " << graph->num_edges << "\n";

    for (int i = 0; i < graph->num_edges; i++) {
        file << graph->row_indices[i] << " " << graph->edge_labels[i] << " " << graph->col_indices[i] << "\n";
    }

    file.close();
}

void readCooFromFile(CooGraph* graph, const char* filename) {
    std::ifstream file(filename);

    file >> graph->num_nodes >> graph->num_edges;

    graph->row_indices = (int *) malloc(graph->num_edges * sizeof(int));
    graph->col_indices = (int *) malloc(graph->num_edges * sizeof(int));
    graph->edge_labels = (int *) malloc(graph->num_edges * sizeof(int));

    for (int i = 0; i < graph->num_edges; i++) {
        file >> graph->row_indices[i] >> graph->edge_labels[i] >> graph->col_indices[i];
    }
    file.close();
}

//TODO: optimize to read chunks of the file at a time
void readGraph(const char* filename, CooGraph* graph, std::unordered_map<int, string>* node_map, std::unordered_map<string, int>* node_map_reverse, std::unordered_map<int, string>* edge_map, std::unordered_map<string, int>* edge_map_reverse, std::unordered_map<int,std::string>* label_nodes, int num_nodes, int num_edges, bool is_undirected) {

    // Open file
    std::fstream file {filename};
    if (!file.is_open()) {
        std::cerr << "Error opening file " << filename << "\n";
        exit(1);
    }
    
    graph->num_nodes = num_nodes;
    graph->num_edges = num_edges;
    int curr_edge = 0;
    graph->row_indices = (int*) malloc(num_edges * sizeof(int));
    graph->col_indices = (int*) malloc(num_edges * sizeof(int));
    graph->edge_labels = (int*) malloc(num_edges * sizeof(int));
    
    int next_node_id = 0, next_edge_label = 0;
    string line, subj, pred, edge;

    while (std::getline(file, line)) {

        if (line.empty()) {
            continue;
        }

        line.pop_back();

        stringstream ss {line};
        ss >> subj >> edge;
        std::getline(ss, pred);

        if (pred == "" || pred == " ") {
            continue;
        }

        if (node_map_reverse->find(subj) == node_map_reverse->end()) {
            node_map->insert({next_node_id, subj});
            node_map_reverse->insert({subj, next_node_id});
            next_node_id++;
        }

        if (node_map_reverse->find(pred) == node_map_reverse->end()) {
            node_map->insert({next_node_id, pred});
            node_map_reverse->insert({pred, next_node_id});
            next_node_id++;
        }

        if (edge_map_reverse->find(edge) == edge_map_reverse->end()) {
            edge_map->insert({next_edge_label, edge});
            edge_map_reverse->insert({edge, next_edge_label});
            next_edge_label++;
        }
        
        int subj_id = node_map_reverse->at(subj);
        int pred_id = node_map_reverse->at(pred);
        int edge_id = edge_map_reverse->at(edge);

        //check if edge is a label edge 
        if (edge.find("label") != std::string::npos || edge.find("alias") != std::string::npos) {
            std::transform(pred.begin(), pred.end(), pred.begin(), ::tolower);
            label_nodes->insert({pred_id, pred});
        }

        graph->row_indices[curr_edge] = subj_id;
        graph->col_indices[curr_edge] = pred_id;
        graph->edge_labels[curr_edge++] = edge_id;

        if (is_undirected) {
            graph->row_indices[curr_edge] = pred_id;
            graph->col_indices[curr_edge] = subj_id;
            graph->edge_labels[curr_edge++] = edge_id;
        }
    }
    file.close();
    std::cerr << "Finished reading graph (" << "nodes: " << graph->num_nodes << ", edges: " << graph->num_edges << ")\n" ;
}

void freeGraph(CooGraph* graph) {
    
    free(graph->row_indices);
    free(graph->col_indices);
    free(graph->edge_labels);

    free(graph);
}

void freeGraph(CsrGraph* graph) {

    free(graph->row_offsets);
    free(graph->col_indices);
    free(graph->edge_labels);

    free(graph);
}

void printGraph(const CooGraph* graph) {
    for (int i = 0; i < graph->num_edges; ++i) {
        std::cout << graph->row_indices[i] << " " << graph->col_indices[i] << " " << graph->edge_labels[i] << "\n";
    }
}

void printGraph(const CooGraph* graph, std::unordered_map<int, string>& node_map, std::unordered_map<int, string>& edge_map, const char* filename) {   std::ofstream file;
    if (filename) {
        // Open the file in append mode
        file.open(filename, std::ofstream::app);
    }
    std::ostream& out = filename != nullptr ? file : std::cout;
    for (int i = 0; i < graph->num_edges; i += 2) {
        out << node_map[graph->row_indices[i]] << " " << edge_map[graph->edge_labels[i]] << " " << node_map[graph->col_indices[i]] << "\n";
    }

    out << "-------------------\n";

    if (filename) {
        file.close();
    }
}

void printGraph(const CsrGraph* graph) {
    for (int i = 0; i < graph->num_nodes; ++i) {
        for (int j = graph->row_offsets[i]; j < graph->row_offsets[i + 1]; ++j) {
            std::cout << i << " " << graph->col_indices[j] << " " << graph->edge_labels[j] << "\n";
        }
    }
}

void printGraph(const CsrGraph* graph, std::unordered_map<int, string>& node_map, std::unordered_map<int, string>& edge_map, const char* filename) {
    //print to file if filename is not null else print to stdout
    std::ofstream file;
    if (filename) {
        file.open(filename);
    }
    std::ostream& out = filename != nullptr ? file : std::cout;
    for (int i = 0; i < graph->num_nodes; ++i) {
        for (int j = graph->row_offsets[i]; j < graph->row_offsets[i + 1]; ++j) {
            out << node_map[i] << " " << edge_map[graph->edge_labels[j]] << " " << node_map[graph->col_indices[j]] << "\n";
        }
    }
    if (filename) {
        file.close();
    }
}
