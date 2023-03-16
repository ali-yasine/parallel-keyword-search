#ifndef _PKS_H_
#define _PKS_H_

#include "graph.h"

void pks(const CsrGraph* graph, const int* query,const int query_num, CsrGraph** result, const int k, const float alpha = 0.1f, const char* filename = nullptr);

#endif
