    subroutine export_data
    use parameters, only: gap, npartitions
    implicit none 
    integer ipart
    open(777, file='gap.dat')
    do ipart=1,npartitions
        write(777,'(i5,x,f12.8)') ipart, gap(ipart)
    enddo
    close(777)
    end subroutine export_data
