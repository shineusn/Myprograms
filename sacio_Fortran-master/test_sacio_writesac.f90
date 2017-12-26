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
!       gfortran -c test_sacio_writesac.f90
!       gfortran test_sacio_writesac.o sacio.o -o test_sacio_writesac
!
program test_sacio_writesac
use sacio
implicit none
integer :: flag
character(len=80) :: filename
real, allocatable, dimension(:) :: data
type(sachead) :: head

filename="testin.sac"
! get data from testin.sac for writing SAC file later
call sacio_readsac(filename, head, data, flag)

filename="testout.sac"
write(*,*) "sacio_writesac begin"
!
!   sacio_writesac
!   Description: Write SAC data file
!   Input:
!       character(len=80) :: filename   filename to be read
!       type(sachead)     :: head       SAC header to be written
!       real, dimension(:):: data       SAC data to be written
!   Output:
!       integer           :: flag       Error code
!   Error code:
!       0:  Succeed
!       1:  Unable to open file
!       5:  Error in writing SAC file
!
call sacio_writesac(filename, head, data, flag)

write(*,*) "check the file of 'testout.sac'"
write(*,*) 'sacio_writesac done'
end program
