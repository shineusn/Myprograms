#!bin/bash
set -x

file="K003.K030.3-.SAC K003.K030.3+.SAC"
dist=297.51

TC=40
alpha=5.0
rs=1.877
bs=1.717


cat > draw.s << EOF
\$keys in
r \$in
color color increment list red blue
gtext software font 1 size small
plabel 'Red=${rs}' position .16 .82 size small
plabel 'Blue=${bs}' position .16 .77 size small
title 'DIST=${dist}KM alpha=${alpha} T=${TC}s' size medium
xlabel 'Time/s' size medium
ylabel 'Normalized Waveform' size medium
xlim 0 150
ylim -1 1
p2
EOF
sac draw.s in ${file}
