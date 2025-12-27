SHELL = /bin/sh
.SUFFIXES: .cc .o

LULESH_EXEC = lulesh

# Choose compiler (serial by default)
SERCXX = nvc++ -DUSE_MPI=0
MPICXX = mpicxx -DUSE_MPI=1
CXX = $(SERCXX)
#CXX = $(MPICXX)

SOURCES2.0 = \
	lulesh.cc \
	lulesh-comm.cc \
	lulesh-util.cc \
	lulesh-init.cc

OBJECTS2.0 = $(SOURCES2.0:.cc=.o)

# SILO (kept as in your file)
SILO_INCDIR = /usr/gapps/silo/4.8/chaos_5_x86_64_ib_pgcc/include
SILO_LIBDIR = /usr/gapps/silo/4.8/chaos_5_x86_64_ib_pgcc/lib

# =========================
# Explicit NVIDIA A100 flags (cc80)
# =========================

# OpenMP target offload for A100:
OMPFLAGS = -mp=gpu -gpu=cc80,fastmath -Minfo=accel

# Host optimization flags:
HOSTOPT = --restrict -O3 -fast -Mautoinline -Minline=levels:20 \
          -Msafeptr -mcmodel=medium -DSEDOV_SYNC_POS_VEL_LATE

# Linker tweak you had:
LINKOPT = -Wl,--no-relax

# Final compile/link flags:
CXXFLAGS = $(HOSTOPT) $(OMPFLAGS)
LDFLAGS  = $(OMPFLAGS) $(LINKOPT)

# =========================

.cc.o: lulesh.h
	@echo "Building $<"
	$(CXX) -c $(CXXFLAGS) -o $@ $<

all: $(LULESH_EXEC)

$(LULESH_EXEC): $(OBJECTS2.0)
	@echo "Linking"
	$(CXX) $(OBJECTS2.0) $(LDFLAGS) -lm -o $@

clean:
	/bin/rm -f *.gpu *.o *~ $(OBJECTS2.0) $(LULESH_EXEC)
	/bin/rm -rf *.dSYM

tar: clean
	cd .. ; tar cvf lulesh-2.0.tar LULESH-2.0 ; mv lulesh-2.0.tar LULESH-2.0
