#画绘出震中分布图,符号尺寸由震级决定,符号颜色由深度决定.
#!/bin/sh

#一些相关参数的设置
#gmtset HEADER_FONT_SIZE 30 OBLIQUE_ANOTATION 0 DEGREE_FORMAT 0

log=103.8/104.2/27.4/27.7
relog=103.9/104.1/27.45/27.62

#制作调色板文件,输出到g.cpt文件。
makecpt -Cseis -T0/30/2 -I > g.cpt

#pscoast -Jm2.5i -R103.7/104.2/27.3/27.7 -Ba1/40m -K -P -W > pzhplot.ps

#画地震目录事件
psbasemap -JX4i -R${log} -X2i \
-B0.2:"Longitude"::,@+o:/0.2:"Latitude"::,@+o::."Catalog Events":WSne -K > eo.ps 
awk '{print $8,$7,$9,$10*0.05}' event.txt | psxy -JX -Cg.cpt -R -Sc -O -K -N >> eo.ps
#画主震
echo 103.993 27.553 |  





#Psscale画颜色标尺,设置调色板文件为g.cpt文件
psscale -Cg.cpt -D4.5i/2i/3i/0.3i -O -K -B2:Depth:/:km: -E >> eo.ps
#画附近断层
psxy -JX -R -W1.0p/black -O -K << ! >> eo.ps
104.0999 27.78207
104.0708 27.74029
104.0195 27.69116
103.9678 27.6348
103.9118 27.58001
103.8603 27.53618
103.8008 27.47577
103.7505 27.43017
103.7127 27.39774
103.6732 27.36072
103.6341 27.32013
103.595  27.27862
103.5648 27.25641
103.5406 27.23541
103.534  27.22878
!
#画剖面直线
# psxy -JX -R -W0.25pta/black -O -K << ! >> eo.ps
# 103.897   27.436  
# 104.186   27.719

# !

#画尺寸标尺
psxy -JX -R -Sc -N -Gblue -O -K << ! >> eo.ps
103.84 27.68 0.05
103.86 27.68 0.1
103.88 27.68 0.15
103.90 27.68 0.20
103.92 27.68 0.25
103.94 27.68 0.30
103.96 27.68 0.35
103.98 27.68 0.40
!
pstext -JX -R -Gblue -O -K << ! >> eo.ps
103.82 27.66 7 0 1 2 M
103.84 27.66 7 0 1 2 1
103.86 27.66 7 0 1 2 2
103.88 27.66 7 0 1 2 3
103.90 27.66 7 0 1 2 4 
103.92 27.66 7 0 1 2 5 
103.94 27.66 7 0 1 2 6
103.96 27.66 7 0 1 2 7
103.98 27.66 7 0 1 2 8
!






