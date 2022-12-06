.SUFFIXES: .f90
################# Compiler flag #####################
FC=mpif90        # IBM-FORTRAN compiler! If you are 
                # using another comppiler, FC should
                # be editted to the availabe one.
################ Processor options ##################
PREFLAGS=
################ Compiler options ###################
#FFLAGS= -O3 -g  -fbacktrace -fcheck=bound -fcheck=all
FFLAGS= -O3 # -g  -fbacktrace -fcheck=bound -fcheck=all
################ Link flags #########################
LFLAGS= -llapack -lblas
################ Directory path for EXE file ########
LPATH= ../bin 
                # You need to change the above path 
                # to your own path address
#####################################################

################ 
WKDIR= .
################ Profram files ######################
MODUL= $(WKDIR)/CONSTANTS.f90    $(WKDIR)/PARAMETERS.f90
CORE= $(WKDIR)/CONSTRUCT_HAMILTONIAN.f90    
PUBLIC= $(WKDIR)/GETPARAM.f90    
MPIRUN= $(WKDIR)/INITMPI.f90
        
OUTPUT=  $(WKDIR)/EXPORT.f90
TRANS= 
MAIN=  $(WKDIR)/MAIN.f90
################ Special files ######################
OTHER= $(WKDIR)/INPUT       
#####################################################
ALL= $(MODUL) $(CORE) $(PUBLIC) $(MPIRUN) $(OUTPUT) $(TRANS) $(MAIN)
################ Execuation #########################
.f90.o:
	$(FC) $(PREFLAGS) $(FFLAGS) -c $*.f90
 ALLOBJ=${ALL:.f90=.o}
 ALLMOD=${ALL:.f90=.mod}
################ Dependencies #######################

############# Create Exe file #######################
diracfinder:  $(ALLOBJ)
#	mv *.mod $(WKDIR) 
	$(FC) $(ALLOBJ) $(LFLAGS)  $(FFLAGS) -o $@
	chmod ugo+r *
	chmod ugo+x diracfinder
#	cp diracfinder $(LPATH)
############# Make tar file #########################
tar:
	rm -f diracfinder.tar
	tar -cvf diracfinder.tar $(ALL) $(OTHER) 
############ Clean ##################################
clean:
	rm -f $(WKDIR)/*.mod $(WKDIR)/*.o $(WKDIR)/*.omp \
              $(WKDIR)/*.lst $(WKDIR)/*.log $(WKDIR)/*.L diracfinder
