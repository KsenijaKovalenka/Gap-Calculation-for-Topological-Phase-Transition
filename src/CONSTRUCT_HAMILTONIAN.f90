      SUBROUTINE construct_hamiltonian
      USE CONSTANTS          ,          ONLY:  TWOPI !unused but may be usefull later?
      USE PARAMETERS         ,          ONLY:  IERR,MYID,NUMPROCS,               & !for mpi
                                             IUH_TRIVIAL,IUH_TOPOLOGICAL,INNKP,  & !file indicies
                                             PREFIX,NBAND,NRPTS,NDEG,            & !basic stuff
                                             NKX,NKY,NKZ,NKPT,                   & !bounds for kmesh
                                             NPARTITIONS,NCONDUCTION,NVALENCE,   &
                                             KX_HBOX,KY_HBOX,KZ_HBOX,            & !kmesh
                                             K1_ORIGIN,K2_ORIGIN,K3_ORIGIN,      & !initial k-point in lattice basis
                                             AVEC, BVEC, RVEC, GAP, TIMING         !basis + rvector array
                                             
                                             
      IMPLICIT NONE
      INCLUDE 'mpif.h'

!-------------------local variables----------------------------
      integer*4 KMAX,KMIN,KNUM
      integer*4 ipart, ikx, iky, ikz, ECOUNTS
      real*8  alpha, KX_ORIGIN, KY_ORIGIN, KZ_ORIGIN
      character(len=100):: line, hamil_file_triv, hamil_file_top, nnkp
      integer*4 i,j,k,i1,i2,ik
      real*8 phase,r1,r2,r3,a,b
      real*8,allocatable:: rwork(:)
      INTEGER*4 lwork,lrwork,info
      COMPLEX*16,ALLOCATABLE:: work(:),Hk_triv(:,:),Hk_top(:,:),Hk(:,:), &
      Hr_triv(:,:,:),Hr_top(:,:,:),Hr_alpha(:,:)
      real*8,allocatable:: ENE(:,:), EIGEN(:,:), klist(:,:), PTIMING(:)
      !  timing
      REAL*8 TENDK, TSTARTK,TPROC(0:NUMPROCS-1)

      TPROC=0D0 
!---------------  reciprocal vectors
      write(nnkp,'(a,a)')trim(adjustl(prefix)),".nnkp"

      open(INNKP,file=trim(adjustl(nnkp)),err=666)

110   read(INNKP,'(a)')line
      if(trim(adjustl(line)).ne."begin real_lattice") goto 110
    
      read(INNKP,*)AVEC
      
111   read(INNKP,'(a)')line
      if(trim(adjustl(line)).ne."begin recip_lattice") goto 111
      
      read(INNKP,*)BVEC
      close(INNKP)
      
!  set up work arrays for ZHEEV
      lwork  = MAX(1,2*NBAND-1)
      lrwork = MAX(1,3*NBAND-1)
      ALLOCATE(work(lwork),rwork(lrwork),Hk(NBAND,NBAND),GAP(NPARTITIONS),PTIMING(NPARTITIONS))

      PTIMING = 0D0     
!  distribute k-points among the avaialble processors
!  first check if NKPT is divisible by NUMPROCS
      IF (MOD(NKPT,NUMPROCS).EQ.0) THEN
         KNUM = NKPT / NUMPROCS  !integer division, number of k-points in the batch
         KMIN = 1 + KNUM * MYID
         KMAX = KNUM * (MYID + 1)
         ALLOCATE(ENE(NBAND,1:KNUM))
         ALLOCATE(EIGEN(NBAND,NKPT))

      ELSE
         KNUM = (NKPT / NUMPROCS)+1          !number of k-points in the batch
         KMIN = 1 + KNUM * MYID
         KMAX = KNUM * (MYID + 1)
         ALLOCATE(ENE(NBAND,1:KNUM))
         ALLOCATE(EIGEN(NBAND,KNUM*NUMPROCS))

      ENDIF 
      
!---------defining k point which previously gave the minimum energy in carthesian co-ords     

      KX_ORIGIN = K1_ORIGIN * BVEC(1,1) + K2_ORIGIN * BVEC(1,2) + K3_ORIGIN * BVEC(1,3)
      KY_ORIGIN = K1_ORIGIN * BVEC(2,1) + K2_ORIGIN * BVEC(2,2) + K3_ORIGIN * BVEC(2,3)
      KZ_ORIGIN = K1_ORIGIN * BVEC(3,1) + K2_ORIGIN * BVEC(3,2) + K3_ORIGIN * BVEC(3,3)
      print*, K1_ORIGIN
      print*, KX_HBOX
      print*, BVEC(1,1)
          
!  generate a uniform 3D k-mesh
      ALLOCATE(KLIST(3,NKPT))
      open(777,file='kmesh.dat')
      K=0
      DO IKX=-NKX,NKX
       DO IKY=-NKY,NKY
        DO IKZ=-NKZ,NKZ
         K=K+1
         klist(1,K) = (float(ikx)/float(nkx))*KX_HBOX + KX_ORIGIN
         klist(2,K) = (float(iky)/float(nky))*KY_HBOX + KY_ORIGIN
         klist(3,K) = (float(ikz)/float(nkz))*KZ_HBOX + KZ_ORIGIN
         write(777, '(3(x,f12.8))') klist(1,K), klist(2,K), klist(3,K)
        ENDDO
       ENDDO
      ENDDO 

!-----define file units for trivial and topological files
      IUH_TRIVIAL = 96
      IUH_TOPOLOGICAL = 95

!--------for now have the two filenames       
      write(hamil_file_triv,'(a,a)')trim(adjustl(prefix)),"_hr_trivial.dat"
      write(hamil_file_top,'(a,a)')trim(adjustl(prefix)),"_hr_topological.dat"

!------read H(R) trivial
      open(IUH_TRIVIAL,file=trim(adjustl(hamil_file_triv)),err=444)
      read(IUH_TRIVIAL,*)
      read(IUH_TRIVIAL,*)
      read(IUH_TRIVIAL,*)
!      read(IUH_TRIVIAL,*)NBAND,nr
      allocate(RVEC(3,NRPTS),Hk_triv(NBAND,NBAND),Hr_triv(NBAND,NBAND,NRPTS),ndeg(NRPTS)) 
      ! read the weighting array
      read(IUH_TRIVIAL,*)ndeg
      do k=1,NRPTS
         do i=1,NBAND
            do j=1,NBAND
               read(IUH_TRIVIAL,*)r1,r2,r3,i1,i2,a,b
               RVEC(1,k)=r1*AVEC(1,1) + r2*AVEC(1,2) + r3*AVEC(1,3)
               RVEC(2,k)=r1*AVEC(2,1) + r2*AVEC(2,2) + r3*AVEC(2,3)
               RVEC(3,k)=r1*AVEC(3,1) + r2*AVEC(3,2) + r3*AVEC(3,3)
               Hr_triv(i1,i2,k)=dcmplx(a,b)
            enddo
         enddo
      enddo
      close(IUH_TRIVIAL)
      
!------read H(R) topological
      open(IUH_TOPOLOGICAL,file=trim(adjustl(hamil_file_top)),err=445)
      read(IUH_TOPOLOGICAL,*)
      read(IUH_TOPOLOGICAL,*)
      read(IUH_TOPOLOGICAL,*)
!      read(IUH_TOPOLOGICAL,*)NBAND,nr
      allocate(Hk_top(NBAND,NBAND),Hr_top(NBAND,NBAND,NRPTS),Hr_alpha(NBAND,NBAND)) !ndeg is weight matrix - same for both
      read(IUH_TOPOLOGICAL,*)ndeg
      do k=1,NRPTS
         do i=1,NBAND
            do j=1,NBAND
               read(IUH_TOPOLOGICAL,*)r1,r2,r3,i1,i2,a,b
               Hr_top(i1,i2,k)=dcmplx(a,b)
            enddo
         enddo
      enddo
      close(IUH_TOPOLOGICAL)


!---- Fourrier transform H(R) to H(k)

    ENE=0d0 !why this one is initialised here and the other inside the loop?
    do ipart=1,npartitions
      TIMING=0D0
      TSTARTK=MPI_WTIME()
      alpha=(float(ipart-1)/float(npartitions-1)*0.15d0) + 0.7d0 !offset and scaling for closer interval
          EIGEN=0D0
          !ENE=0d0 ?
          IK=0
          do K=KMIN,MIN(KMAX, NKPT)
             IK=IK+1
             Hk=(0d0,0d0)
             do j=1,NRPTS
                phase=0.0d0
                do i=1,3
                   phase=phase+klist(i,k)*RVEC(i,j)
                enddo
                Hr_alpha = alpha*Hr_top(:,:,j)+(1d0-alpha)*Hr_triv(:,:,j)
                Hk=Hk+Hr_alpha*dcmplx(cos(phase),-sin(phase))/float(ndeg(j))

             enddo
             !-----------find energies---------------------------------
             call zheev('V','U',NBAND,Hk,NBAND,ENE(:,ik),work,lwork,rwork,info)
          enddo

          !  gather the information corresponding to the distributed k-points
          TENDK=MPI_WTIME()
          TPROC(MYID)=TENDK-TSTARTK
          ECOUNTS=KNUM*NBAND
          CALL MPI_GATHER(ENE,ECOUNTS,MPI_DOUBLE_PRECISION,   &
                      EIGEN,ECOUNTS,MPI_DOUBLE_PRECISION,     &
                      0,MPI_COMM_WORLD,IERR)

                      
          GAP(IPART) = MINVAL(EIGEN(NCONDUCTION,:)) - MAXVAL(EIGEN(NVALENCE,:))
          !EF(IPART) = (MINVAL(EIGEN(13,:)) + MAXVAL(EIGEN(12,:)))/2D0

          CALL MPI_REDUCE(TPROC,TIMING,NUMPROCS,MPI_DOUBLE_PRECISION,MPI_SUM, &
          0,MPI_COMM_WORLD,IERR)
          PTIMING(IPART) = TIMING(MYID) 

    enddo
    TIMING = SUM(PTIMING)

    IF(MYID.NE.0) DEALLOCATE(EIGEN)
    DEALLOCATE(klist,Hr_triv,Hr_top,Hr_alpha,Hk_triv,Hk_top,Hk,RVEC) !ndeg?
    DEALLOCATE(work,rwork,ENE)
    RETURN    
    
      
!---------error traces--------------------------------------- 

444   write(*,'(3a)')'ERROR: input file "',trim(adjustl(hamil_file_triv)),' not found'
      stop
445   write(*,'(3a)')'ERROR: input file "',trim(adjustl(hamil_file_top)),' not found'
      stop
666   write(*,'(3a)')'ERROR: input file "',trim(adjustl(nnkp)),' not found'
      stop

      END SUBROUTINE construct_hamiltonian
      


