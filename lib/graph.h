#ifndef __GRAPH_H__
#define __GRAPH_H__

struct CooGraph {
    unsigned int num_nodes;
    unsigned int num_edges;
    unsigned int* row_indices;
    unsigned int* col_indices;
    unsigned int* edge_labels;
};

struct CsrGraph {
    unsigned int num_nodes;
    unsigned int num_edges;
    unsigned int* row_offsets;
    unsigned int* col_indices;
    unsigned int* edge_labels;

    unsigned int getEdgeLabel(unsigned int src, unsigned int dst) {
        if (src == dst) 
            return 0;
        
        for(unsigned int i = row_offsets[src]; i < row_offsets[src + 1]; ++i)
            if(col_indices[i] == dst)
                return edge_labels[i];
                
        return UINT_MAX; 
    }
};

CsrGraph* cooToCSR(CooGraph* coo);

CooGraph* readGraph(const char* filename);
#endif  