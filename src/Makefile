NVCC=nvcc
LDFLAGS=-Xcompiler="-pthread" -lcurand
CUDAFLAGS=-dc 
SOURCES=sha3.cu main.cu
OBJECTS=$(SOURCES:.cu=.o)
EXECUTABLE=test

all: $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	$(NVCC) $(OBJECTS) $(LDFLAGS) -o $@

%.o:    %.cu
	$(NVCC) $(CUDAFLAGS) $< -o $@

clean:
	rm -f test *.o $(EXECUTABLE) 
