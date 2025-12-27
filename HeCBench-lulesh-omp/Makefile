#===============================================================================
# User Options
#===============================================================================

CC        = pgc++
OPTIMIZE  = yes
DEBUG     = no
DEVICE    = gpu
VERIFY    = no
LAUNCHER  =

#===============================================================================
# Program name & source code list
#===============================================================================

program = lulesh

source = lulesh.cc \
        lulesh-viz.cc \
        lulesh-util.cc \
        lulesh-init.cc

obj = $(source:.cc=.o)

#===============================================================================
# Sets Flags
#===============================================================================

# Standard Flags
CFLAGS := $(EXTRA_CFLAGS) -std=c++14 -Wall

# A100 linker tweak (same as before)
LDFLAGS = -Wl,--no-relax

# Debug Flags
ifeq ($(DEBUG),yes)
  CFLAGS += -g
  LDFLAGS  += -g
endif

# Verify kernel results
ifeq ($(VERIFY),yes)
  CFLAGS += -DVERIFY
endif

# Optimization Flags
ifeq ($(OPTIMIZE),yes)
  CFLAGS += -O3
endif

#===============================================================================
# Explicit NVIDIA A100 OpenMP offload flags (cc80) + same host opts as before
#===============================================================================

ifeq ($(DEVICE),gpu)
  # Same host optimizations you used before:
  CFLAGS += --restrict -O3 -fast -Mautoinline -Minline=levels:20 \
           -Msafeptr -mcmodel=medium -DSEDOV_SYNC_POS_VEL_LATE

  # OpenMP GPU offload for A100 (cc80), same “style” as common-a100-flags.mk:
  CFLAGS += -mp=gpu -gpu=cc80,fastmath -Minfo=mp -Mlarge_arrays

  # (Optional) If you also want -mp on host even without offload directives,
  # you already have it via -mp=gpu above.
else
  # CPU-only OpenMP (kept from your original)
  CFLAGS += -qopenmp
endif

#===============================================================================
# Targets to Build
#===============================================================================

$(program): $(obj)
	$(CC) $(CFLAGS) $(obj) -o $@ $(LDFLAGS)

%.o: %.cc lulesh.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(program) $(obj)

test: $(program)
	./$(program) -i 1 -s 32 -r 11 -b 1 -c 1

run: $(program)
	$(LAUNCHER) ./$(program) -i 100 -s 128 -r 11 -b 1 -c 1

