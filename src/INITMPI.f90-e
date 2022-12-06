    SUBROUTINE INIT_MPI
    USE PARAMETERS               ,             ONLY: IERR,MYID,NUMPROCS
    IMPLICIT NONE
    INCLUDE ‘mpif.h’
        Call MPI_INIT( IERR )
        Call MPI_COMM_RANK( MPI_COMM_WORLD, MYID, IERR )
        Call MPI_COMM_SIZE( MPI_COMM_WORLD, NUMPROCS , IERR )
!        Write(*,*) ‘Process’, myid, ' of ’, NUMPROCS , ‘is alive.’
    END SUBROUTINE INIT_MPI