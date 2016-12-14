#  
#  Copyright 2016 Christopher MacMackin <cmacmackin@gmail.com>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  

# Directories
SDIR := ./src
TDIR := ./tests
MDIR := ./mod
ODIR := ./objs
PFUNIT = $(HOME)/Code/pfunit-$(F90)

# Output
EXEC := 
TEXEC := tests.x
LIB := flogging.a
PREFIX := $(HOME)/.local
LIBDIR := $(PREFIX)/lib
INCDIR := $(PREFIX)/include
BINDIR := $(PREFIX)/bin

# Include paths internal to project
PROJECT_INCDIRS := $(FMDIR) $(TDIR)

# The compiler
VENDOR ?= GNU
VENDOR_ = $(shell echo $(VENDOR) | tr A-Z a-z)

ifeq ($(VENDOR_),intel)
  F90      := ifort
  FCFLAGS  := -O0 -g -I$(INC) -module $(MDIR) -traceback -assume realloc_lhs
  LDFLAGS  := -O0 -g -traceback
  COVFLAGS := 
else
  F90      := gfortran-6
  FCFLAGS  := -O0 -g -fcheck=all -J$(MDIR)
  LDFLAGS  := -O0 -g
  COVFLAGS := -fprofile-arcs -ftest-coverage
endif

FPP := fypp
FPP_FLAGS := -DDEBUG -n

# Include paths
FCFLAGS += $(PROJECT_INCDIRS:%=-I%) -I$(INCDIR) -I/usr/include -I$(PFUNIT)/mod

# Libraries for use at link-time
LIBS := -L$(LIBDIR) -lface
LDFLAGS += $(LIBS)

# A regular expression for names of modules provided by external libraries
# and which won't be contained in the module directory of this codebase
EXTERNAL_MODS := ^iso_(fortran_env|c_binding)|ieee_(exceptions|arithmetic|features)|openacc|omp_lib(_kinds)?|mpi|pfunit_mod|face$$

# Extensions of Fortran files, case insensitive
F_EXT := f for f90 f95 f03 f08 f15

# Temporary work variables
_F_EXT := $(F_EXT) $(shell echo $(F_EXT) | tr a-z A-Z)
null :=
space := $(null) $(null)
EXT_PATTERN_GREP := '.*\.\($(subst $(space),\|,$(_F_EXT))\)'
EXT_PATTERN_SED := 's/([^ ]*)\.($(subst $(space),|,$(_F_EXT)))/\1.o/g;'
FPP_PATTERN_GREP := '.*\.\(fpp\|FPP\)'
FPP_PATTERN_SED := 's/([^ ]*)\.(fpp|FPP)/\1.o/g;'

# Objects to compile
OBJS := $(shell find $(SDIR) -iregex $(EXT_PATTERN_GREP) | sed -r $(EXT_PATTERN_SED))
OBJS += $(shell find $(SDIR) -iregex $(FPP_PATTERN_GREP) | sed -r $(FPP_PATTERN_SED))
TOBJS := $(patsubst %.pf,%.o,$(wildcard $(TDIR)/*.pf))

.PRECIOUS: %.F90

# "make" builds all
all: all_objects tests

all_objects: $(OBJS)

exec: $(EXEC) 

$(EXEC): $(OBJS)
	$(F90) $^ $(LDFLAGS) -o $@

install_exec: exec
	cp $(EXEC) $(BINDIR)

tests: $(TEXEC)
	./$(TEXEC)

$(TEXEC): $(TOBJS) $(LIB)
	$(F90) -I$(PFUNIT)/include $(PFUNIT)/include/driver.F90 $(COVFLAGS) \
		$(FCFLAGS) $^ $(LIBS) -L$(PFUNIT)/lib -lpfunit -o $@

lib: $(LIB)

$(LIB): $(OBJS)
	$(AR) rcs $@ $^

install_lib: lib
	cp $(LIB) $(LIBDIR)
	cp $(MDIR)/*.mod $(INCDIR)

ifeq ($(MAKECMDGOALS),clean)
else ifeq ($(MAKECMDGOALS),doc)
else
-include $(OBJS:.o=.d) $(TOBJS:.o=.d)
endif

%.d: %.pf get_deps
	./get_deps $< $$\(MDIR\) "$(EXTERNAL_MODS)" $(PROJECT_INCDIRS) > $@

%.d: %.fpp get_deps
	./get_deps $< \$$\(MDIR\) "$(EXTERNAL_MODS)" $(PROJECT_INCDIRS) > $@

%.d: %.FPP get_deps
	./get_deps $< \$$\(MDIR\) "$(EXTERNAL_MODS)" $(PROJECT_INCDIRS) > $@

# General rule for building Fortran files, where $(1) is the file extension
define fortran_rule
%.o: %.$(1) $(FMOD) | $(MDIR)
	$$(F90) $$(COVFLAGS) $$(FCFLAGS) -c $$< -o $$@

%.d: %.$(1) get_deps
	./get_deps $$< \$$$$\(MDIR\) "$$(EXTERNAL_MODS)" $$(PROJECT_INCDIRS) > $$@
endef

# Register compilation rules for each Fortran extension
$(foreach EXT,$(_F_EXT),$(eval $(call fortran_rule,$(EXT))))

%.F90: %.pf
	$(PFUNIT)/bin/pFUnitParser.py $< $@

%.F90: %.fpp
	$(FPP) $(FPP_FLAGS) $< $@

%.F90: %.FPP
	$(FPP) $(FPP_FLAGS) $< $@

$(MDIR):
	@mkdir -p $@

clean: clean_obj clean_mod clean_deps clean_backups

clean_obj:
	@echo Deleting all object files
	@/bin/rm -rf $(OBJS) $(TOBJS)

clean_mod:
	@echo Deleting all module files
	@/bin/rm -rf $(MDIR)

clean_deps:
	@echo Deleting all dependency files
	@/bin/rm -rf $(OBJS:.o=.d) $(TOBJS:.o=.d)

clean_exec:
	@echo Deleting executable file
	@/bin/rm -rf $(EXEC)

clean_backups:
	@echo Deleting emacs backup files
	@/bin/rm -rf $(shell find '.' -name '*~') $(shell find '.' -name '\#*\#')

doc: documentation.md
	ford $<

.PHONEY: all all_objects exec install_exec tests lib install_lib clean \
	 clean_obj clean_mod clean_backups doc
