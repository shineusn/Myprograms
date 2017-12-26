#!/bin/sh
set -x

cat > ngcfile << EOF
9 30.0 3.8
4.0 40.0 1.0
A101.A608.-.SAC
A101.L236.-.SAC
A608.L236.-.SAC
ST.A101.A608.-.SAC
ST.A101.L236.-.SAC
ST.A608.L236.-.SAC
DIF.A101.A608.A.SAC
DIF.A101.L236.A.SAC
DIF.A608.L236.A.SAC


EOF

#gfortran nbc.f90 libcalpltf-ubuntu.a -o nbc
gfortran ngc.f90 libcalpltf-cyg.a -o ngc
./ngc
ls *plt
#plotxvig < Tt.plt
#plotnps -G < *.plt > *.ps

