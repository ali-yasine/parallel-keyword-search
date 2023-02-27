#include "graph.h"
void cooToCSR(CooGraph* coo, CsrGraph* graph) {

    // Initialize fields
    graph->num_nodes = coo->num_nodes;
    graph->num_edges = coo->num_edges;
    graph->row_offsets = (unsigned int*) calloc((coo->num_nodes + 1),sizeof(unsigned int));
    graph->col_indices = (unsigned int*) calloc(coo->num_edges, sizeof(unsigned int) );
    graph->edge_labels = (unsigned int*) calloc(coo->num_edges, sizeof(unsigned int));

    //histogram rows
    for(unsigned int i = 0; i < coo->num_edges; ++i) {
        graph->row_offsets[coo->row_indices[i]]++;
    }
    
    //prefix sum row offsets
    unsigned int sumBeforeNextRow = 0;
    for(unsigned int row = 0; row < graph->num_nodes; ++row) {
        unsigned int sumBeforeRow = sumBeforeNextRow;
        sumBeforeNextRow += graph->row_offsets[row];
        graph->row_offsets[row] = sumBeforeRow;
    }
    graph->row_offsets[graph->num_nodes] = sumBeforeNextRow;

    //Bin the edges
    for (unsigned int i = 0; i < coo->num_edges; ++i) {
        unsigned int row = coo->row_indices[i];
        unsigned int j = graph->row_offsets[row]++;
        graph->col_indices[j] = coo->col_indices[i];
        graph->edge_labels[j] = coo->edge_labels[i];
    }

    //Restore row offsets
    for (unsigned int row = graph->num_nodes; row > 0; --row) {
        graph->row_offsets[row] = graph->row_offsets[row - 1];
    }

    graph->row_offsets[0] = 0;

}

void readGraph(const char* filename, CooGraph* graph) {
    FILE* fp = fopen(filename, "r");

    //Initialize fields
    int x = 1;
    x |= fscanf(fp, "%u", &graph->num_nodes);
    x |= fscanf(fp, "%u", &graph->num_edges);
    graph->row_indices = (unsigned int*) malloc(sizeof(unsigned int) * (graph->num_edges));
    graph->col_indices = (unsigned int*) malloc(sizeof(unsigned int) * graph->num_edges);
    graph->edge_weights = (unsigned int*) malloc(sizeof(unsigned int) * graph->num_edges);

    //Read the graph
    for(unsigned int i = 0; i < graph->num_edges; ++i) {
        x |= fscanf(fp, "%u", &graph->row_indices[i]);
        x |= fscanf(fp, "%u", &graph->col_indices[i]);
        x |= fscanf(fp, "%u", &graph->edge_weights[i]);
    }   

    fclose(fp);
}
