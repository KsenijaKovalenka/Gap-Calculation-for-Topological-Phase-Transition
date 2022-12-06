	MODULE PARAMETERS
	IMPLICIT NONE
!	INCLUDE 'mpif.h'
!   MPI varibales
	INTEGER IERR,MYID,NUMPROCS
!   input file units 
	INTEGER IUH, IUH_TRIVIAL, IUH_TOPOLOGICAL, INNKP, IIN
!   k-points & bands
	INTEGER NBAND,NKX,NKY,NKZ,NKPT,NVALENCE,NCONDUCTION,NPARTITIONS
	REAL*8  KX_HBOX,KY_HBOX,KZ_HBOX
	REAL*8  K1_ORIGIN,K2_ORIGIN,K3_ORIGIN
!   real-space sampling
	INTEGER NRPTS
	INTEGER,ALLOCATABLE::NDEG(:),RVEC(:,:)
!   real-space hamiltonian
   !need either two distinct or nothing
!	COMPLEX*16,ALLOCATABLE::HAMR(:,:,:)
!   Fermi level
	REAL*8 EFERMI
!   lattice parameters
	REAL*8 AVEC(3,3),BVEC(3,3)
!   prefix of the wannier outputs
	CHARACTER(LEN=100)PREFIX
!   work arrays
        REAL(8),ALLOCATABLE::EIGEN(:,:),VELOC(:,:),MAGNET(:,:,:),GAP(:),TIMING(:)
        INTEGER,ALLOCATABLE:: IKMAP(:,:,:)
!   control keys for plotting velocity and magnetization
        LOGICAL PLOT_VELOC, PLOT_MAGNET
	END MODULE PARAMETERS

!============================================================
! initialization
!============================================================
        SUBROUTINE INIT_PARAM
        USE CONSTANTS          ,          ONLY: TWOPI
        USE PARAMETERS         ,          ONLY:  IERR,MYID,NUMPROCS,IIN,             &
                                                 IUH,INNKP,PREFIX,NBAND,NRPTS,       &
                                                 NKX,NKY,NKZ,NKPT,                   &
                                                 NVALENCE,NCONDUCTION,NPARTITIONS,   &
                                                 KX_HBOX,KY_HBOX,KZ_HBOX,            &
                                                 K1_ORIGIN,K2_ORIGIN,K3_ORIGIN,      &
                                                 EIGEN,IKMAP,PLOT_VELOC,PLOT_MAGNET
        IMPLICIT NONE
        INCLUDE 'mpif.h'
        CHARACTER(LEN=100)LINE,POSLINE,NNKPLINE
        CHARACTER(LEN=300)TOKEN,VALUE
        LOGICAL CASE_HR,CASE_POS,CASE_NNKP,CASE_IN
! initialize input units
        IUH  = 99
        INNKP= 98
        IIN  = 97
! open master input 
        INQUIRE(FILE='INPUT',EXIST=CASE_IN)
        IF(.NOT.CASE_IN) GO TO 149
        OPEN(IIN,FILE='INPUT',STATUS='OLD',ERR=149)
!============================================================
!  READ MANDATORY PARAMETERS
!============================================================
! 1. read prfix and inquire the related files
        TOKEN='PREFIX'
        CALL GETPARAM(TOKEN,VALUE,IIN)
        PREFIX=TRIM(ADJUSTL(VALUE))
        WRITE(LINE,'(2A)')TRIM(ADJUSTL(PREFIX)),'_hr_trivial.dat'
        INQUIRE(FILE=TRIM(ADJUSTL(LINE)),EXIST=CASE_HR)
        IF(.NOT.CASE_HR) GO TO 150
        WRITE(NNKPLINE,'(2A)')TRIM(ADJUSTL(PREFIX)),'.nnkp'
        INQUIRE(FILE=TRIM(ADJUSTL(NNKPLINE)),EXIST=CASE_NNKP)
        IF(.NOT.CASE_NNKP) GO TO 152

! 2. read NKX, NKY and NKZ and set NKPT
        TOKEN='NKX'
        CALL GETPARAM(TOKEN,VALUE,IIN)
        IF(LEN_TRIM(VALUE).NE.0) THEN
	
           READ(VALUE,*,ERR=154) NKX
        ELSE
           GO TO 154
        ENDIF
        TOKEN='NKY'
        CALL GETPARAM(TOKEN,VALUE,IIN)
        IF(LEN_TRIM(VALUE).NE.0) THEN
           READ(VALUE,*,ERR=155) NKY
	
        ELSE
           GO TO 155
        ENDIF
        TOKEN='NKZ'
        CALL GETPARAM(TOKEN,VALUE,IIN)
        IF(LEN_TRIM(VALUE).NE.0) THEN
           READ(VALUE,*,ERR=156) NKZ
	
        ELSE
           GO TO 156
        ENDIF
! 3. read NVALENCE and NCONDUCTION
        TOKEN='NVALENCE'
        CALL GETPARAM(TOKEN,VALUE,IIN)
        IF(LEN_TRIM(VALUE).NE.0) THEN
           READ(VALUE,*,ERR=157) NVALENCE
	
        ELSE
           GO TO 157
        ENDIF

        TOKEN='NCONDUCTION'
        CALL GETPARAM(TOKEN,VALUE,IIN)
        IF(LEN_TRIM(VALUE).NE.0) THEN
           READ(VALUE,*,ERR=158) NCONDUCTION
	
        ELSE
           GO TO 158
        ENDIF

        TOKEN='NPARTITIONS'
        CALL GETPARAM(TOKEN,VALUE,IIN)
        IF(LEN_TRIM(VALUE).NE.0) THEN
           READ(VALUE,*,ERR=1158) NPARTITIONS
	
        ELSE
           NPARTITIONS=2D0
        ENDIF

        NKPT=(2*NKX+1)*(2*NKY+1)*(2*NKZ+1)
        ALLOCATE(IKMAP(-NKX:NKX,-NKY:NKY,-NKZ:NKZ))
!============================================================
!  READ OPTIONAL PARAMETERS
!============================================================
! 1. read k-oorigin
        TOKEN='K1_ORIGIN'
        CALL GETPARAM(TOKEN,VALUE,IIN)
        IF(LEN_TRIM(VALUE).NE.0) THEN
         
           READ(VALUE,*,ERR=159) K1_ORIGIN
        ELSE
           K1_ORIGIN=0D0
        ENDIF

        TOKEN='K2_ORIGIN'
        CALL GETPARAM(TOKEN,VALUE,IIN)
        IF(LEN_TRIM(VALUE).NE.0) THEN

           READ(VALUE,*,ERR=160) K2_ORIGIN
        ELSE
           K2_ORIGIN=0D0
        ENDIF

        TOKEN='K3_ORIGIN'
        CALL GETPARAM(TOKEN,VALUE,IIN)
        IF(LEN_TRIM(VALUE).NE.0) THEN

           READ(VALUE,*,ERR=161) K3_ORIGIN
        ELSE
           K3_ORIGIN=0D0
        ENDIF
! 2. read k-box half sizes
 
        TOKEN='KX_HBOX'
        CALL GETPARAM(TOKEN,VALUE,IIN)
        IF(LEN_TRIM(VALUE).NE.0) THEN
	
           READ(VALUE,*,ERR=162) KX_HBOX
        ELSE
           KX_HBOX=0D0
        ENDIF

        TOKEN='KY_HBOX'
        CALL GETPARAM(TOKEN,VALUE,IIN)
        IF(LEN_TRIM(VALUE).NE.0) THEN
	
           READ(VALUE,*,ERR=163) KY_HBOX
        ELSE
           KY_HBOX=0D0
        ENDIF

        TOKEN='KZ_HBOX'
        CALL GETPARAM(TOKEN,VALUE,IIN)
        IF(LEN_TRIM(VALUE).NE.0) THEN
	
           READ(VALUE,*,ERR=164) KZ_HBOX
        ELSE
           KZ_HBOX=0D0
        ENDIF
!============================================================
!  Done with INPUT; close it
!============================================================
        CLOSE(IIN)
!============================================================
!  READ OTHER PARAMETERS in case_hr.dat and case.nnk
!============================================================
        OPEN(IUH  ,FILE=TRIM(ADJUSTL(LINE)),STATUS='OLD',ERR=150)
        OPEN(INNKP,FILE=TRIM(ADJUSTL(NNKPLINE)),STATUS='OLD',ERR=152)
! FIND THE NUMBER OF BANDS and R-vectors
        READ(IUH,*)
        READ(IUH,*,END=153)NBAND
        READ(IUH,*,END=153)NRPTS
        REWIND(IUH)
        RETURN
! Error messages
 149    IF(MYID.eq.0) THEN
          WRITE(*,'(A,/,A,/,A,/,A)') &
          '-----------------------------------------------', &
          '  FATAL ERROR: MASTER FILE "INPUT" NOT FOUND.  ', &
          '                 PROGRAM ABORTED               ', &
          '-----------------------------------------------'
        ENDIF
        STOP
 150    IF(MYID.eq.0) THEN
          WRITE(*,'(A,/,3A,/,A,/,A)') &
          '-----------------------------------------------', &
          '  FATAL ERROR: ',TRIM(ADJUSTL(LINE)),' NOT FOUND.', &
          '                 PROGRAM ABORTED               ', & 
          '-----------------------------------------------' 
        ENDIF
        STOP
 152    IF(MYID.eq.0) THEN
          WRITE(*,'(A,/,3A,/,A,/,A)') &
          '-----------------------------------------------', &
          '  FATAL ERROR: ',TRIM(ADJUSTL(NNKPLINE)),' NOT FOUND.', &
          '                 PROGRAM ABORTED               ', &
          '-----------------------------------------------' 
        ENDIF
        STOP
 153    IF(MYID.eq.0) THEN
          WRITE(*,'(A,/,3A,/,A,/A)') &
          '-----------------------------------------------', &
          '  FATAL ERROR: REACHED END OF ',TRIM(ADJUSTL(LINE)),'.', &
          '                 PROGRAM ABORTED               ', &
          '-----------------------------------------------' 
        ENDIF
        STOP
 154    IF(MYID.eq.0) THEN
          WRITE(*,'(A,/,A,/,A,/,A)') &
          '-----------------------------------------------', &
          '            FATAL ERROR: INVALID NKX.  ',         &
          '                 PROGRAM ABORTED               ', &
          '-----------------------------------------------'
        ENDIF
        STOP
 155    IF(MYID.eq.0) THEN
          WRITE(*,'(A,/,A,/,A,/,A)') &
          '-----------------------------------------------', &
          '            FATAL ERROR: INVALID NKY.  ',         &
          '                 PROGRAM ABORTED               ', &
          '-----------------------------------------------'
        ENDIF
        STOP
 156    IF(MYID.eq.0) THEN
          WRITE(*,'(A,/,A,/,A,/,A)') &
          '-----------------------------------------------', &
          '            FATAL ERROR: INVALID NKZ.  ',         &
          '                 PROGRAM ABORTED               ', &
          '-----------------------------------------------'
        ENDIF
        STOP
 157    IF(MYID.eq.0) THEN
          WRITE(*,'(A,/,A,/,A,/,A)') &
          '-----------------------------------------------', &
          '           FATAL ERROR: INVALID NVALENCE.  ',         &
          '                 PROGRAM ABORTED               ', &
          '-----------------------------------------------'
        ENDIF
        STOP
 158    IF(MYID.eq.0) THEN
          WRITE(*,'(A,/,A,/,A,/,A)') &
          '-----------------------------------------------', &
          '           FATAL ERROR: INVALID NCONDUCTION.  ',         &
          '                 PROGRAM ABORTED               ', &
          '-----------------------------------------------'
        ENDIF
        STOP
1158    IF(MYID.eq.0) THEN
         WRITE(*,'(A,/,A,/,A,/,A)') &
         '-----------------------------------------------', &
         '           FATAL ERROR: INVALID NPARTITIONS.  ',         &
         '                 PROGRAM ABORTED               ', &
         '-----------------------------------------------'
       ENDIF
       STOP       
 159    IF(MYID.eq.0) THEN
          WRITE(*,'(A,/,A,/,A,/,A)') &
          '-----------------------------------------------', &
          '         FATAL ERROR: INVALID K1_ORIGIN.  ',         &
          '                 PROGRAM ABORTED               ', &
          '-----------------------------------------------'
        ENDIF
        STOP
 160    IF(MYID.eq.0) THEN
          WRITE(*,'(A,/,A,/,A,/,A)') &
          '-----------------------------------------------', &
          '         FATAL ERROR: INVALID K2_ORIGIN.  ',         &
          '                 PROGRAM ABORTED               ', &
          '-----------------------------------------------'
        ENDIF
        STOP
 161    IF(MYID.eq.0) THEN
          WRITE(*,'(A,/,A,/,A,/,A)') &
          '-----------------------------------------------', &
          '         FATAL ERROR: INVALID K3_ORIGIN.  ',         &
          '                 PROGRAM ABORTED               ', &
          '-----------------------------------------------'
        ENDIF
        STOP
 162    IF(MYID.eq.0) THEN
          WRITE(*,'(A,/,A,/,A,/,A)') &
          '-----------------------------------------------', &
          '          FATAL ERROR: INVALID KX_HBOX.  ',         &
          '                 PROGRAM ABORTED               ', &
          '-----------------------------------------------'
        ENDIF
        STOP
 163    IF(MYID.eq.0) THEN
          WRITE(*,'(A,/,A,/,A,/,A)') &
          '-----------------------------------------------', &
          '          FATAL ERROR: INVALID KY_HBOX.  ',         &
          '                 PROGRAM ABORTED               ', &
          '-----------------------------------------------'
        ENDIF
        STOP
 164    IF(MYID.eq.0) THEN
          WRITE(*,'(A,/,A,/,A,/,A)') &
          '-----------------------------------------------', &
          '          FATAL ERROR: INVALID KZ_HBOX.  ',         &
          '                 PROGRAM ABORTED               ', &
          '-----------------------------------------------'
        ENDIF
        STOP
        END SUBROUTINE INIT_PARAM


