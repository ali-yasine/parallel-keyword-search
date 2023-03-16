#ifndef __GRAPH_H__
#define __GRAPH_H__
#include <climits>
#include <map>
#include <string>
#include <unordered_map>

using std::string;

struct CooGraph {
    int num_nodes;
    int num_edges;
    int* row_indices;
    int* col_indices;
    int* edge_labels;
};

struct CsrGraph {
    int num_nodes;
    int num_edges;
    int* row_offsets;
    int* col_indices;
    int* edge_labels;

    int getEdgeLabel(int src, int dst) {
        if (src == dst) 
            return 0;
        
        for(int i = row_offsets[src]; i < row_offsets[src + 1]; ++i)
            if(col_indices[i] == dst)
                return edge_labels[i];
                
        return INT_MAX; 
    }
};

struct CSCMatrix {
    int num_nodes;
    int num_edges;
    int* col_offsets;
    int* row_indices;
    int* edge_labels;
};

void cooToCSR(const CooGraph* coo, CsrGraph* graph);

void readGraph(const char* filename, CooGraph* graph, std::unordered_map<int, string>* node_map, std::unordered_map<string, int>* node_map_reverse, std::unordered_map<int, string>* edge_map, std::unordered_map<string, int>* edge_map_reverse);

void freeGraph(CooGraph* graph);

void freeGraph(CsrGraph* graph);

#endif  
