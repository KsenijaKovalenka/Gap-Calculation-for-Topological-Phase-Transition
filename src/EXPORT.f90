    subroutine export_data
    use parameters, only: gap, npartitions
    implicit none 
    integer ipart
    real*8  alpha
    open(777, file='gap.dat')
    do ipart=1,npartitions
        alpha=(float(ipart-1)/float(npartitions-1)*0.15d0) + 0.7d0
        write(777,'(f12.8,x,f12.8)') alpha, gap(ipart)
    enddo
    close(777)
    end subroutine export_data
