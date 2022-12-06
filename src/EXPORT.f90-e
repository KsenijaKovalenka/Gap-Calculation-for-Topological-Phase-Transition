    subroutine export_data
    use parameters, only: gap, npartitions
    implicit none 
    integer ipart
    open(777, file='gap.dat')
    do ipart=1,npartitions
        write(777,'()') ipart, gap(ipart)
    enddo
    close(777)
    end subroutine export_data