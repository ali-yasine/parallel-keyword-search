
NVCC        = nvcc
NVCC_FLAGS  = -std=c++17 
OBJ         = main.o pks.o top_down.o util.o graph.o index.o pks_kernel.o gpu_util.o pks_bitwise.o
EXE         = pks
OPT_LEVEL   = -O3

ifeq ($(debug), 1)
	NVCC_FLAGS += -g -G
	OPT_LEVEL = -O0
endif

default: $(EXE)

%.o: %.cu
	$(NVCC) $(NVCC_FLAGS) -c -o $@ $<

$(EXE): $(OBJ)
	$(NVCC) $(NVCC_FLAGS) $(OPT_LEVEL) $(OBJ) -o $(EXE)

clean:
	rm -rf $(OBJ) $(EXE)

