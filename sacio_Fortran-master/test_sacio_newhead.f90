!Copyright  2015  Liang Wang & Dongdong Tian
!
!Licensed under the Apache License, Version 2.0 (the "License");
!you may not use this file except in compliance with the License.
!You may obtain a copy of the License at
!
!    http://www.apache.org/licenses/LICENSE-2.0
!
!Unless required by applicable law or agreed to in writing, software
!distributed under the License is distributed on an "AS IS" BASIS,
!WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
!See the License for the specific language governing permissions and
!limitations under the License.!
!
!   Author：
!       Liang Wang         E-mail: wangliang0222@foxmail.com
!       Dongdong Tian      E-mail: seisman.info@gmail.com
!
!   Compile:
!       gfortran -c sacio.f90
!       gfortran -c test_sacio_newhead.f90
!       gfortran test_sacio_newhead.o sacio.o -o test_sacio_newhead
!
program test_sacio_newhead
use sacio
implicit none
type(sachead) :: head
real, allocatable, dimension(:) :: data
character(len=80) :: filename
integer :: flag, i

write(*, *) "sacio_newhead begin:"
! create a header for evenly-spaced time series
call sacio_newhead(head, 0.01, 100, 0.0)
write(*, *) "npts=", head%npts
write(*, *) "delta=", head%delta
write(*, *) "b=", head%b
write(*, *) "e=", head%e
write(*, *) "o=", head%o

! write data to file
filename = "test_sacio_newhead_out.sac"
allocate(data(1:head%npts))
do i=1, head%npts
    data(i) = 1.0
end do
call sacio_writesac(filename, head, data, flag)
write(*, *) "check file 'test_sacio_newhead_out.sac'"
end program
