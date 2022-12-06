    SUBROUTINE INIT_MPI
    USE PARAMETERS               ,             ONLY: IERR,MYID,NUMPROCS,TIMING
    IMPLICIT NONE
    INCLUDE 'mpif.h'
        Call MPI_INIT( IERR )
        Call MPI_COMM_RANK( MPI_COMM_WORLD, MYID, IERR )
        Call MPI_COMM_SIZE( MPI_COMM_WORLD, NUMPROCS , IERR )
!        Write(*,*) ‘Process’, myid, ' of ’, NUMPROCS , ‘is alive.’
        ALLOCATE(TIMING(0:NUMPROCS-1))
    END SUBROUTINE INIT_MPI