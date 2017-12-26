#!/bin/sh
set -x

echo $0 $1 $2 $3 $4 $5 $6 $7 $8

DIST=$1
HS=$2
AZ=$3
Mw=$4

STK=$5   #走向 0~360
RAKE=$6  #滑动角 -180~180
DIP=$7   #倾角 0~90

NAME=$8

######
# 生成震中距文件和速度模型文件
######
#采样从发震时刻开始
cat > dfile << EOF
$DIST 0.02 1024 65.0 -100.0
EOF
cat > model.d << EOF
MODEL.01
AK135 MODEL
ISOTROPIC
KGS
FLAT EARTH
1-D
CONSTANT VELOCITY
LINE08
LINE09
LINE10
LINE11
H(KM) VP(KM/S) VS(KM/S) RHO(GM/CC) QP    QS   ETAP ETAS  FREFP FREFS
20.00  5.8000   3.4600    2.7200  767.0 500.0  0.0  0.0   1.0   1.0
15.00  6.5000   3.8500    2.9200  767.0 500.0  0.0  0.0   1.0   1.0
42.50  8.0400   4.4800    3.3198  262.0 141.0  0.0  0.0   1.0   1.0
42.50  8.0450   4.4900    3.3455  262.0 141.0  0.0  0.0   1.0   1.0
45.00  8.0500   4.5000    3.3713  262.0 141.0  0.0  0.0   1.0   1.0
45.00  8.1750   4.5090    3.3985  262.0 141.0  0.0  0.0   1.0   1.0
50.00  8.3000   4.5230    3.4258  262.0 141.0  0.0  0.0   1.0   1.0
50.00  8.4825   4.6090    3.4561  262.0 141.0  0.0  0.0   1.0   1.0
50.00  8.6650   4.6960    3.4864  262.0 141.0  0.0  0.0   1.0   1.0
50.00  8.8475   4.7830    3.5167  256.0 111.0  0.0  0.0   1.0   1.0
50.00  9.3600   5.0800    3.7557  256.0 111.0  0.0  0.0   1.0   1.0
50.00  9.5280   5.1860    3.8175  296.0 134.0  0.0  0.0   1.0   1.0
50.00  9.6960   5.2920    3.8793  296.0 134.0  0.0  0.0   1.0   1.0
50.00  9.8640   5.3980    3.9410  296.0 134.0  0.0  0.0   1.0   1.0
50.00 10.0320   5.5040    4.0028  840.0 569.0  0.0  0.0   1.0   1.0
00.00 10.7900   5.9600    4.3714  840.0 569.0  0.0  0.0   1.0   1.0
EOF
#####
hprep96 -M model.d  -HS ${HS} -HR 0 -d dfile -ALL
hspec96 > hspec96.out
hpulse96 -D -p -1 4 > file96
fmech96 -A ${AZ} -ROT -D ${DIP} -R ${RAKE} \
-S ${STK} -MW ${Mw} < file96 > 3.96
f96tosac -B 3.96

cp B00101Z00.sac ${NAME}.SAC


# cp B00101Z00.sac Z1.sac
# cp B00201Z00.sac Z2.sac
# cp B00301Z00.sac Z3.sac
# cp B00401Z00.sac Z4.sac
# cp B00501Z00.sac Z5.sac
# cp B00601Z00.sac Z6.sac
# cp B00102R00.sac R1.sac
# cp B00202R00.sac R2.sac
# cp B00302R00.sac R3.sac
# cp B00402R00.sac R4.sac
# cp B00502R00.sac R5.sac
# cp B00602R00.sac R6.sac
# cp B00103T00.sac T1.sac
# cp B00203T00.sac T2.sac
# cp B00303T00.sac T3.sac
# cp B00403T00.sac T4.sac
# cp B00503T00.sac T5.sac
# cp B00603T00.sac T6.sac
rm B*sac

