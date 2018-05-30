ASMSOURCES = M7Test.asm              \
             HWDriver.asm            \
             M7TestMain.asm          \
             ShipSprite.asm          \
             initreg.asm

#-------------------------------------------------------------------------------
CL65	= ../../cc65/bin/cl65.exe
LD65	= ../../cc65/bin/ld65.exe
OBJECTS   = $(addprefix objs/,$(notdir $(ASMSOURCES:.asm=.o)))
LIBRARIES =
#-------------------------------------------------------------------------------

all :	$(OBJECTS) $(LIBRARIES)
	$(LD65) -o M7Test.smc --config M7Test.cfg --obj $(OBJECTS)

.SUFFIXES : .asm .o

objs/%.o : %.asm
	$(CL65) -t none -o objs/$*.o -c $*.asm

clean :
	rm -f objs/*.o
	rm -f *.smc
