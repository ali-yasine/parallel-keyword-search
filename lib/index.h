#ifndef _INDEX_H_
#define _INDEX_H_

void getVertexInformativeness(const CsrGraph* csr, float* vertex_w);
float averageDistanceInGraph(const CsrGraph* graph, const int num_samples = 10000);
void writeGraphIndex(const char* filename, float* vertex_w, float avg_hops, int graph_size);
void readGraphIndex(const char* filename, float* vertex_w, float& avg_hops, int graph_size);

#endif