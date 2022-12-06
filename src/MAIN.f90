    program diracfinder
    use constants, only : twopi
    USE PARAMETERS       ,    ONLY: IERR,MYID,NUMPROCS,TIMING
    use parameters 
    implicit NONE
    CHARACTER ZDATE*8,ZTIME*10,ZZONE*5
    call init_mpi(ierr)
    IF(MYID.EQ.0) THEN
       CALL DATE_AND_TIME(ZDATE,ZTIME,ZZONE)
       WRITE(*,'(20(A,/),12A,/,A)')                                     &
       "        _ _                 __ _                              ",&
       "     __| (_)_ __ __ _  ___ / _(_)_ __   __| | ___ _ __        ",& 
       "    / _` | | '__/ _` |/ __| |_| | '_ \ / _` |/ _ \ '__|       ",&
       "   | (_| | | | | (_| | (__|  _| | | | | (_| |  __/ |          ",&
       "    \__,_|_|_|  \__,_|\___|_| |_|_| |_|\__,_|\___|_|          ",&
       "                                           Version 1.0        ",&
       "-------------------------------------------------------       ",&
       "  This utility program interpolates energy gap between        ",&
       "  the two adiabatically connected  phases  of  a given        ",&
       "  electronic system. The program reads all the  inputs        ",& 
       "  from a master file named INPUT.                             ",&
       "                                                              ",&
       "  For   addtional  information or  technical  support,        ",&
       "  contact the developer Ksenija Kovalenka at:                 ",&
       "           ksenija.kovalenka@student.manchester.ac.uk         ",&
       "                                                              ",&
       "  Last undate: December 2, 2022                               ",&
       "-------------------------------------------------------       ",&
       "                All rights reserved (c)                       ",&
       "-------------------------------------------------------       ",&
       '            DATE: ',ZDATE(1:4),'-',ZDATE(5:6),'-',              &
       ZDATE(7:8),' TIME: ',ZTIME(1:2),':',ZTIME(3:4),':',              &
       ZTIME(5:6),                                                      &
       "-------------------------------------------------------       "
        WRITE(*,'(A,I4,A)') '  Running over ', NUMPROCS,' cores'
    ENDIF

    call init_param
    call construct_hamiltonian
    IF(MYID.EQ.0) THEN
       call export_data
       CALL DATE_AND_TIME(ZDATE,ZTIME,ZZONE)
       WRITE(*,'(A,/,A,/,2(A,I6,A,I3,A,/),A)') &
       '----------------------------------------------------------', &
       '                     Normal Termination                   ', &
       ' Total CPU time up to now :', int(sum(TIMING)/60d0), &
       ' min ',int(mod(sum(TIMING),60d0)),' sec',     &
       ' Total user time up to now:',int(maxval(TIMING)/60d0), &
       ' min ',int(mod(maxval(TIMING),60d0)),' sec',     &
       '----------------------------------------------------------'
    ENDIF
    call mpi_finalize(ierr)
    end program diracfinder
