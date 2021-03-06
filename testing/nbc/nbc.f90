program nbc
 implicit none
!-----
! 此程序用于窄带滤波提取基阶面波相速度频散信息
! 作者：王清东，武大09研，固体地球物理学
! 时间：2011-05-16 09:31:45
!
! 部分参数说明：
! ntc     I*4  窄带滤波周期数
! VNPTS,PNPTS  I*4  速度窗,绘图窗点数
! rhdr    R*4  SAC文件头实型变量
! ihdr    I*4  SAC文件头整型变量
! chdr    C*   SAC文件头字符型变量
! sacname C*   输入的SAC文件名
! tc      R*4  窄带滤波中心周期
! t0,v0   R*4  输入的理论模型的周期与对应波速
! NPTS,DT,B,O,DIST  SAC文件头变量:采样点数,采样间隔,第一个采样点,发震时刻,震中距
! data,dataw   R*4  SAC文件振幅信息
! tt      R*4  各采样点走时
! wv      R*4  各采样点对应波速
! TttC    R*4  得到的频散信息
! sT_t,sT_C    R*4  窄带滤波波形信息矩阵
! tcb,wvb I*4  搜索到的频散点
!
! 文件说明：
! nbcfile      控制文件:
!              第一行为输入的文件数,理论模型的周期与对应波速 num,t0,v0
!              第二行为窄带滤波起始中心周期,截止周期,周期间隔 btc,etc,dtc
!              自第三行一下为输入的文件名 sacname
!
!
! 部分子程序说明：
! brsach,brsac 读取SAC二进制文件信息
! KKFFT        快速傅里叶变换，来源：Fortran常用算法程序集源码-徐士良清华大学
! nbf          窄带滤波
! band         搜索与输入的理论点最接近的频散点
! seek         搜索频散点
! putshd       波形灰度图
! putwave      波形图+得到的频散信息图
! putxy        绘制搜索到的频散曲线和初始搜索点
!-----
 integer*4::i,j,num,NPTS,VNPTS,PNPTS,IRU,nerr
 integer*4::ntc,pl,ph,vl,vh,tcb,ttb,wvb,bbt,bbv
 real*4::t0,v0,btc,dtc,etc,hf,dy1,dyn
 real*4,allocatable::tc(:),tt(:),wv(:),tt1(:),temp1(:),temp2(:)
 real*4,allocatable::sT_t(:,:),sT_C(:,:),TttC(:,:)
 real*4,parameter::vlow=2.0e0,vhigh=7.0e0      !速度窗(信号窗)
 real*4,parameter::plow=2.0e0,phigh=5.0e0      !绘图窗
 character*60::name
 character*60,allocatable::sacname(:)

 real*4,allocatable::data(:),dataw(:)
 common/sachdr/rhdr,ihdr,chdr
 real*4::rhdr(70)
 integer*4::ihdr(40)
 character*8::chdr(24)

 open(10,file='info.txt')                    !程序运行信息文件

!读取控制文件信息 
 open(11,file='nbcfile',status='old')
 read(11,*) num,t0,v0
 read(11,*) btc,etc,dtc
 allocate(sacname(num))
 do i=1,num
  read(11,*) sacname(i)
  call filesta(sacname(i),nerr)
  if(nerr.eq.1) then
   print*, 'The file ',trim(sacname(i)),' dosen`t exist'
   goto 99
  endif
  sacname(i)=adjustl(sacname(i))
  print*, trim(sacname(i))
 enddo
 close(11)

 ntc=anint(abs((etc-btc)/dtc))+1
 allocate(tc(ntc))
 do i=1,ntc
  tc(i)=btc+(i-1)*dtc
 enddo
 IRU=100
! DT=rhdr(1)     B=rhdr(6)      O=rhdr(8)      DIST=rhdr(51)
! STLA=rhdr(32)  STLO=rhdr(33)  STEL=rhdr(34)  STDP=rhdr(35)
! EVLA=rhdr(36)  EVLO=rhdr(37)  EVEL=rhdr(38)  EVDP=rhdr(39)
! NZYEAR=ihdr(1) NZJDAY=ihdr(2) NZHOUR=ihdr(3) NZMIN=ihdr(4)
! NZSEC=ihdr(5)  NZMSEC=ihdr(6) NPTS=ihdr(10)  KSTNM=chdr(1)
 do i=1,num
  call brsach(IRU,sacname(i),nerr)           !读SAC文件头，提取必要信息
  print*, 'dist= ',rhdr(51)
  !lengh=len(trim(sacname(i)))
  NPTS=ihdr(10)
  !对互相关文件,发震时刻O为0
  vh=anint((rhdr(51)/vlow-rhdr(6))/rhdr(1))+1     !确定速度窗(信号窗)
  vl=anint((rhdr(51)/vhigh-rhdr(6))/rhdr(1))+1
  if(vh.gt.NPTS) vh=NPTS
  if(vl.lt.1) vl=1
  if(vh.lt.0) then
   print*, 'The V-window set is wrong, please check!'
   goto 99
  endif
  !vh=NPTS
  !vl=1
  VNPTS=vh-vl+1
  ph=anint((rhdr(51)/plow-rhdr(6))/rhdr(1))+1     !确定绘图窗
  pl=anint((rhdr(51)/phigh-rhdr(6))/rhdr(1))+1
  PNPTS=ph-pl+1
  !print*, 'vh=',vh,'vl=',vl
  !print*, 'ph=',ph,'pl=',pl
  allocate(tt1(VNPTS),dataw(VNPTS),temp1(VNPTS))
  allocate(sT_t(0:PNPTS,0:ntc),sT_C(0:PNPTS,0:ntc))
  allocate(tt(PNPTS),wv(PNPTS),temp2(PNPTS))
  sT_t(0,0)=rhdr(51)
  sT_C(0,0)=rhdr(51)
  do j=1,VNPTS
   tt1(j)=rhdr(6)+(vl+j-2)*rhdr(1)
  enddo
  do j=1,PNPTS
   tt(j)=rhdr(6)+(pl+j-2)*rhdr(1)
   sT_t(j,0)=tt(j)
   wv(j)=phigh+(j-1)*(plow-phigh)/(PNPTS-1)
   sT_C(j,0)=wv(j)
  enddo
  sT_t(0,1:ntc)=tc(1:ntc)
  sT_C(0,1:ntc)=tc(1:ntc)
  !print*,wv1(1),wv(1),wv(2)-wv(1)
!读取波形信息并进行窄带滤波
  allocate(data(NPTS))
  call brsac(IRU,NPTS,sacname(i),data,nerr)
  dataw(1:VNPTS)=data(vl:vh)
  do j=1,ntc
   if(tc(j).le.20.0e0) then
    hf=0.0035e0
   else if(tc(j).ge.150.0e0) then
    hf=0.016e0
   else
    hf=0.0001e0*tc(j)+0.0018e0
   endif
   !hf=0.005e0
   call nbf(dataw,VNPTS,rhdr(1),tc(j),hf)
   temp1=dataw
   call nor(temp1,VNPTS)
   dy1=(temp1(pl-vl+1)-temp1(pl-vl))/(tt1(pl-vl+1)-tt1(pl-vl))
   dyn=(temp1(pl-vl+PNPTS+1)-temp1(pl-vl+PNPTS))/(tt1(pl-vl+PNPTS+1)-tt1(pl-vl+PNPTS))
   !print*, dy1,dyn
   call espl1(tt1,temp1,VNPTS,dy1,dyn,rhdr(51)/wv,PNPTS,temp2)
   !call spline3(VNPTS,wv1,temp1,PNPTS,wv,temp2)
   call nor(temp2,PNPTS)
   sT_C(1:PNPTS,j)=temp2(1:PNPTS)
   temp2(1:PNPTS)=dataw(pl-vl+1:pl-vl+PNPTS)
   call nor(temp2,PNPTS)
   sT_t(1:PNPTS,j)=temp2(1:PNPTS)
   dataw(1:VNPTS)=data(vl:vh)
  enddo
  !sT_C=sT_t
  !sT_C(1:PNPTS,0)=rhdr(51)/sT_t(1:PNPTS,0)
  deallocate(data,dataw)
  name=trim(sacname(i))//'.TC'
  open(IRU,file=name)
  do j=0,PNPTS
   write(IRU,*) sT_C(j,:)
  enddo
  close(IRU)
!由初始搜索点搜索相速度频散信息
  call band(tc,ntc,t0,tcb,nerr)
  call band(tt,PNPTS,rhdr(51)/v0,ttb,nerr)
  call band(wv,PNPTS,v0,wvb,nerr)
  !print*, tcb,ttb,wvb
  allocate(TttC(ntc,6))
  bbt=ttb
  bbv=wvb
!搜索:走时-周期矩阵;(相速度-周期矩阵)
  do j=tcb,1,-1
   call seek(sT_t,PNPTS,ntc,j,ttb,nerr)
   TttC(j,1)=tc(j)
   TttC(j,2)=tt(ttb)
   TttC(j,3)=rhdr(51)/tt(ttb)
   TttC(j,4)=rhdr(51)/(tt(ttb)+tc(j)/8)
   TttC(j,5)=rhdr(51)/tt(ttb)-rhdr(51)/(tt(ttb)+tc(j)/8)
   TttC(j,6)=ttb
   !call seek(sT_C,PNPTS,ntc,j,wvb,nerr)
   !TttC(j,6)=wv(wvb)
   !TttC(j,7)=wv(wvb)-rhdr(51)/tt(ttb)
   !TttC(j,8)=wvb
  enddo
  do j=tcb+1,ntc
   call seek(sT_t,PNPTS,ntc,j,bbt,nerr)
   TttC(j,1)=tc(j)
   TttC(j,2)=tt(bbt)
   TttC(j,3)=rhdr(51)/tt(bbt)
   TttC(j,4)=rhdr(51)/(tt(bbt)+tc(j)/8)
   TttC(j,5)=rhdr(51)/tt(bbt)-rhdr(51)/(tt(bbt)+tc(j)/8)
   TttC(j,6)=bbt
   !call seek(sT_C,PNPTS,ntc,j,bbv,nerr)
   !TttC(j,6)=wv(bbv)
   !TttC(j,7)=wv(bbv)-rhdr(51)/tt(bbt)
   !TttC(j,8)=bbv
  enddo
  name=trim(sacname(i))//'.C'
  open(IRU,file=name)
  write(IRU,'(a,a,f8.2,a,f6.2,a,f6.3,a)') trim(sacname(i)),'   DIST= ',rhdr(51),'  (t0,v0)= (',t0,',',v0,')'
  write(IRU,120)
  120 format('Period'2x'Travel Time'2x'C'6x'C-G'4x'dCG'2x'TT-Point')
  do j=1,ntc
   write(IRU,'(f6.2,2x,5f8.3)') TttC(j,:)
  enddo
  close(IRU)
!图示化:周期-速度图
  call draw(sT_C,ntc,PNPTS,TttC,trim(sacname(i)),t0,v0)

  deallocate(sT_t,sT_C,tt,wv,tt1,temp1,temp2,TttC)
 enddo

 99 continue
 deallocate(sacname,tc)
end program


subroutine filesta(name,nerr)
 implicit none
 integer*4::nerr
 character*(*)::name
 logical::alive
 nerr=0
 inquire(file=name,exist=alive)
 if(alive.eqv..false.) then
  !print*, 'The file ',trim(name),' dosen`t exist'
  nerr=1
 endif
 return
end subroutine


subroutine brsach(IRU,name,nerr)
!-----
!       IRU I*4 logical unit for IO
!       name    C*  Name of file to be opened
!       rhdr    R*4 Real header
!       ihdr    I*4 Integer Header
!       chdr    C*  Character Header
!       nerr    I*4 -1 file does not exist
!               -2 data points in file exceed dimension
!
!       NOTE IF THE BINARY FILE HAS MORE THAN LN POINTS, THEN ONLY
!       LN POINTS ARE USED
!-----
!  This routine reads waveform data written in SAC binary format.
!
!  Written by Hafidh A. A. Ghalib, 1988.
!-----
 implicit none
 integer*4::i,IRU,nerr
 logical::ext
 common/sachdr/rhdr,ihdr,chdr
 real*4::rhdr(70)
 integer*4::ihdr(40)
 character*8::chdr(24)
 character*(*)::name
!-----
!  Read real and integer header blocks to find actual number
!  of waveform data points which is stored in ihdr(10).
!-----
 inquire(file=name,exist=ext)
 if(.not.ext) then
  ihdr(10)=0
  nerr=-1
  return
 endif
 nerr=0
 !open(IRU,file=name,form='unformatted',access='direct',recl=440,status='old')
 !read(IRU,rec=1) (rhdr(i),i=1,70),(ihdr(i),i=1,40)
 open(IRU,file=name,form='unformatted',access='direct',recl=632,status='old')
 read(IRU,rec=1) (rhdr(i),i=1,70),(ihdr(i),i=1,40),(chdr(i),i=1,24)
 close(IRU)
 return
end subroutine


subroutine brsac(IRU,LN,name,data,nerr)
!-----
!       IRU I*4 logical unit for IO
!       LN  I*4 length of data array
!       name    C*  Name of file to be opened
!       rhdr    R*4 Real header
!       ihdr    I*4 Integer Header
!       chdr    C*  Character Header
!       data    R*4 Array of trace values
!       nerr    I*4 -1 file does not exist
!               -2 data points in file exceed dimension
!
!       NOTE IF THE BINARY FILE HAS MORE THAN LN POINTS, THEN ONLY
!       LN POINTS ARE USED
!-----
!  This routine reads waveform data written in SAC binary format.
!
!  Written by Hafidh A. A. Ghalib, 1988.
!-----
 implicit none
 integer*4::i,IRU,LN,nerr,maxpts,nbytes,ndat,nread,ndat1,irec,nl,nh
 real*4::data(LN)
 logical::ext
 common/sachdr/rhdr,ihdr,chdr
 real*4::rhdr(70)
 integer*4::ihdr(40)
 character*8::chdr(24)
 character*(*)::name
!  Read real and integer header blocks to find actual number
!  of waveform data points which is stored in ihdr(10).
! print*, name
 inquire(file=name,exist=ext)
 if(.not.ext) then
  ihdr(10)=0
  nerr=-1
  return
 endif
 nerr=0 
 open(IRU,file=name,form='unformatted',access='direct',recl=440,status='old')
 read(IRU,rec=1) (rhdr(i),i=1,70),(ihdr(i),i=1,40)
 close(IRU)
!  Read header and waveform data blocks using recored length of 158*4=632.
 if(ihdr(10).gt.LN) then
  maxpts=LN
  ihdr(10)=LN
  nerr=-2
 else 
  maxpts=ihdr(10)
  nerr=0
 endif
 nbytes=632+4*maxpts
 nread=0
!  because of SUNOS Fortran problems with IO transfers 
!  more than 2048 bytes, read these  chunks in 
 ndat=maxpts
 if(nbytes.gt.2048) then
  open(IRU,file=name,form='unformatted',access='direct',recl=2048)
  ndat1=(2048-632)/4
  irec=1
  read(IRU,rec=irec,err=1001) (rhdr(i),i=1,70),   &
                              (ihdr(i),i=1,40),   &
                              (chdr(i),i=1,24),   &
                              (data(i),i=1,ndat1)
  nread=nread+ndat1
  1000 continue
  nl=nread+1
  nh=nl+512-1
  if(nh.gt.ndat) then
   nh=ndat
  endif
  if(nl.gt.ndat) goto 1001
  irec=irec+1
  read(IRU,rec=irec,err=1001) (data(i),i=nl,nh)
  nread=nread+(nh-nl+1)
  goto 1000
  1001 continue
  close(IRU)
 else
  open(IRU,file=name,form='unformatted',access='direct',recl=nbytes)
  read(IRU,rec=1) (rhdr(i),i=1,70),   &
                  (ihdr(i),i=1,40),   &
                  (chdr(i),i=1,24),   &
                  (data(i),i=1,ndat)
  close(IRU)
 endif
 if(ihdr(10).gt.LN) then
  maxpts=LN
  ihdr(10)=LN
 else 
  maxpts=ihdr(10)
 endif
 ihdr(10)=maxpts
 return
end subroutine


subroutine nbf(data,n,dt,tc,hf)
! tc:滤波中心周期
! hf:频率窗半宽度
 implicit none
 integer*4::i,n,logn,nfft
 real*4::data(n),dt,df,tc,hf,fc,f1,f2,f,nb
 real*4,parameter::pai=3.14159265358e0
 real*4,allocatable::PR(:),PI(:),FR(:),FI(:)
 !logn=floor(log10(real(n))/log10(2.0e0))+1
 !nfft=2**logn
 call npow2(n,nfft,logn)
 !print*, 'logn=',logn,'nfft=',nfft
 fc=1.0e0/tc
 df=1.0e0/(nfft*dt)
 do while(df.gt.hf)
  nfft=2*nfft
  logn=logn+1
  df=1.0e0/(nfft*dt)
 enddo
 f1=fc-hf
 f2=fc+hf
 allocate(PR(nfft),PI(nfft),FR(nfft),FI(nfft))
 PR=0.0e0
 PI=0.0e0
 FR=0.0e0
 FI=0.0e0
 call taper(data,n,0.005)
 PR(1:n)=data(1:n)
 call KKFFT(PR,PI,nfft,logn,FR,FI,0,0)
 !print*, b,npts,dt,t0,n,m
 do i=1,nfft/2+1
  f=(i-1)*df
  if(f.ge.f1.and.f.le.f2) then
   nb=(cos(pai*(f-fc)/hf)+1.0e0)/2
  else
   nb=0.0e0
  endif
  PR(i)=FR(i)*nb
  PI(i)=FI(i)*nb
 enddo
 PR(1)=PR(1)/2
 PI(1)=PI(1)/2
 PR(nfft/2+1)=PR(nfft/2+1)/2
 PI(nfft/2+1)=PI(nfft/2+1)/2
 PR(nfft/2+2:nfft)=0.0e0
 PI(nfft/2+2:nfft)=0.0e0       !令负频率为零
 call taper(PR,nfft,0.005)
 call taper(PI,nfft,0.005)
 call KKFFT(PR,PI,nfft,logn,FR,FI,1,0)
 data(1:n)=2*FR(1:n)
 deallocate(PR,PI,FR,FI)
 return
end subroutine


subroutine spline3(n,x,y,m,t,u)
!subroutine spline3(n,x,y,m,t,u,du,ddu,sum)
! 三次样条插值
! n = the number of the data samples
! m = the number of the  interpolation points you want to produce
! x(n)= epochs of sample points
! y(n)= ddualue of function at samples points
! t(m)= epochs of the interpolation points
! u(m)= ddualues of function at interpolation points
! du(m)= the first degree differential(dao suo)
! ddu(m)= the second degree differential(dao shu)
! sum = calculus(ji fen)
! a(n),b(n),c(n),d(n)= the working array
! reference: 丁月蓉，天文数据处理(for interpolation and differential)；
!            徐士良，fortran常用算法程序集(for calculus)。
 implicit none
 integer*4::n,m,i,j,j1,j2,j3,l
 real*4::e,f,rr,ss,tt,aa,dd,bb,cc
 real*4::x(n),y(n),t(m),u(m),a(n),b(n),c(n),d(n),du(m),ddu(m),sum(m)
 a(1)=0.0d0
 d(1)=0.0d0
 d(n)=0.0d0
 c(n)=0.0d0
 a(n)=1.0d0
 b(1)=1.0d0
 c(1)=-1.0d0
 b(n)=-1.0d0
 l=n-1
 do 5 i=2,l
  a(i)=(x(i)-x(i-1))/6.0d0
  c(i)=(x(i+1)-x(i))/6.0d0
  b(i)=2.0d0*(a(i)+c(i))
 5 d(i)=(y(i+1)-y(i))/(x(i+1)-x(i))-(y(i)-y(i-1))/(x(i)-x(i-1))
 c(1)=c(1)/b(1)
 d(1)=d(1)/b(1)
 do 10 i=2,n
  c(i)=c(i)/(b(i)-a(i)*c(i-1))
 10 d(i)=(d(i)-a(i)*d(i-1))/(b(i)-a(i)*c(i-1))
 a(n)=d(n)
 do 15 i=1,l
  j=n-i
 15 a(j)=d(j)-c(j)*a(j+1)
 do 30 j1=1,m
  f=t(j1)
  do 20 j2=1,n-1
   if(x(j2).le.f.and.f.le.x(j2+1)) goto 25
  20 continue
  goto 30
  25 e=x(j2+1)-x(j2)
  rr=(a(j2)*(x(j2+1)-f)**3+a(j2+1)*(f-x(j2))**3)/6.0d0/e
  ss=(x(j2+1)-f)*(y(j2)/e-a(j2)*e/6.0d0)
  tt=(f-x(j2))*(y(j2+1)/e-a(j2+1)*e/6.0d0)
  aa=(a(j2+1)*(f-x(j2))**2)/2.0d0/e
  dd=(a(j2)*(x(j2+1)-f)**2)/2.0d0/e
  bb=(y(j2+1)-y(j2))/e
  cc=(a(j2+1)-a(j2))*e/6.0d0
  du(j1)=aa+bb-cc-dd
  u(j1)=rr+ss+tt
  ddu(j1)=(a(j2)*(x(j2+1)-f)+a(j2+1)*(f-x(j2)))/e
 30 continue
 do 33 i=1,m
  do 33 j3=1,i-1
   if(j3.ne.m) then
    e=t(j3+1)-t(j3)
   else
    e=t(m)-t(m-1)
   endif
   sum(i)=sum(i)+.5d0*e*(u(j3+1)+u(j3))-e**3*(ddu(j3)+ddu(j3+1))/24.0d0
 33 continue
 !print *, u
 return
end subroutine


subroutine espl1(x,y,n,dy1,dyn,xx,m,s)
!subroutine espl1(x,y,n,dy1,dyn,xx,m,dy,ddy,s,ds,dds,t,h)
!给定端点一阶导数的三次样条插值-徐士良
 implicit none
 integer*4::n,m,j,i
 real*4::dy1,dyn,t,h0,h1,beta,alpha
 real*4::x(n),y(n),xx(m),dy(n),ddy(n),s(m),ds(m),dds(m),h(n)
 dy(1)=0.0e0
 h(1)=dy1
 h0=x(2)-x(1)
 do j=2,n-1
  h1=x(j+1)-x(j)
  alpha=h0/(h0+h1)
  beta=(1.0e0-alpha)*(y(j)-y(j-1))/h0
  beta=3.0e0*(beta+alpha*(y(j+1)-y(j))/h1)
  dy(j)=-alpha/(2.0e0+(1.0e0-alpha)*dy(j-1))
  h(j)=(beta-(1.0e0-alpha)*h(j-1))
  h(j)=h(j)/(2.0e0+(1.0e0-alpha)*dy(j-1))
  h0=h1
 enddo
 dy(n)=dyn
 do j=n-1,1,-1
  dy(j)=dy(j)*dy(j+1)+h(j)
 enddo
 do j=1,n-1
  h(j)=x(j+1)-x(j)
 enddo
 do j=1,n-1
  h1=h(j)*h(j)
  ddy(j)=6.0e0*(y(j+1)-y(j))/h1-2.0e0*(2.0e0*dy(j)+dy(j+1))/h(j)
 enddo
 h1=h(n-1)*h(n-1)
 ddy(n)=6.0e0*(y(n-1)-y(n))/h1+2.0e0*(2.0e0*dy(n)+dy(n-1))/h(n-1)
 t=0.0e0
 do i=1,n-1
  h1=0.5e0*h(i)*(y(i)+y(i+1))
  h1=h1-h(i)*h(i)*h(i)*(ddy(i)+ddy(i+1))/24.0e0
  t=t+h1
 enddo
 do 70 j=1,m
  if(xx(j).ge.x(n)) then
   i=n-1
  else
   i=1
 60 if (xx(j).gt.x(i+1)) then
    i=i+1
    goto 60
   endif
  endif
  h1=(x(i+1)-xx(j))/h(i)
  s(j)=(3.0e0*h1*h1-2.0e0*h1*h1*h1)*y(i)
  s(j)=s(j)+h(i)*(h1*h1-h1*h1*h1)*dy(i)
  ds(j)=6.0e0*(h1*h1-h1)*y(i)/h(i)
  ds(j)=ds(j)+(3.0e0*h1*h1-2.0e0*h1)*dy(i)
  dds(j)=(6.0e0-12.0e0*h1)*y(i)/(h(i)*h(i))
  dds(j)=dds(j)+(2.0e0-6.0e0*h1)*dy(i)/h(i)
  h1=(xx(j)-x(i))/h(i)
  s(j)=s(j)+(3.0e0*h1*h1-2.0e0*h1*h1*h1)*y(i+1)
  s(j)=s(j)-h(i)*(h1*h1-h1*h1*h1)*dy(i+1)
  ds(j)=ds(j)-6.0e0*(h1*h1-h1)*y(i+1)/h(i)
  ds(j)=ds(j)+(3.0e0*h1*h1-2.0e0*h1)*dy(i+1)
  dds(j)=dds(j)+(6.0e0-12.0e0*h1)*y(i+1)/(h(i)*h(i))
  dds(j)=dds(j)-(2.0e0-6.0e0*h1)*dy(i+1)/h(i)
 70 continue
 return
end subroutine


SUBROUTINE KKFFT(PR,PI,N,K,FR,FI,L,IL)
!L=0 for fft;L=1 for ifft
!IL=0 不计算模与幅角;IL=1 计算模与幅角
 IMPLICIT NONE
 INTEGER*4::I,N,K,IT,L,IL,M,IS,J,NV,L0
 REAL*4::PR(N),PI(N),FR(N),FI(N),P,Q,S,VR,VI,PODDR,PODDI
 DO IT=0,N-1
  M=IT
	IS=0
	DO I=0,K-1
	 J=M/2
	 IS=2*IS+(M-2*J)
	 M=J
  ENDDO
	FR(IT+1)=PR(IS+1)
	FI(IT+1)=PI(IS+1)
 ENDDO
 PR(1)=1.0E0
 PI(1)=0.0E0
 PR(2)=COS(6.283185306E0/N)
 PI(2)=-SIN(6.283185306E0/N)
 IF(L.NE.0) PI(2)=-PI(2)
 DO I=3,N
	P=PR(I-1)*PR(2)
	Q=PI(I-1)*PI(2)
	S=(PR(I-1)+PI(I-1))*(PR(2)+PI(2))
	PR(I)=P-Q
	PI(I)=S-P-Q
 ENDDO
 DO IT=0,N-2,2
	VR=FR(IT+1)
	VI=FI(IT+1)
	FR(IT+1)=VR+FR(IT+2)
	FI(IT+1)=VI+FI(IT+2)
	FR(IT+2)=VR-FR(IT+2)
	FI(IT+2)=VI-FI(IT+2)
 ENDDO
 M=N/2
 NV=2
 DO L0=K-2,0,-1
	M=M/2
	NV=2*NV
	DO IT=0,(M-1)*NV,NV
	 DO J=0,(NV/2)-1
	  P=PR(M*J+1)*FR(IT+J+1+NV/2)
	  Q=PI(M*J+1)*FI(IT+J+1+NV/2)
	  S=PR(M*J+1)+PI(M*J+1)
	  S=S*(FR(IT+J+1+NV/2)+FI(IT+J+1+NV/2))
	  PODDR=P-Q
	  PODDI=S-P-Q
	  FR(IT+J+1+NV/2)=FR(IT+J+1)-PODDR
    FI(IT+J+1+NV/2)=FI(IT+J+1)-PODDI
	  FR(IT+J+1)=FR(IT+J+1)+PODDR
	  FI(IT+J+1)=FI(IT+J+1)+PODDI
   ENDDO
  ENDDO
 ENDDO
 IF(L.NE.0) THEN
  DO I=1,N
	 FR(I)=FR(I)/N
	 FI(I)=FI(I)/N
  ENDDO
 ENDIF
 IF(IL.NE.0) THEN
  DO I=1,N
	 PR(I)=SQRT(FR(I)*FR(I)+FI(I)*FI(I))
   PI(I)=ATAN(FI(I)/FR(I))*360.0E0/6.283185306E0
   !将相位还原为[0,2pai],即[0,360]
   IF(FR(I).LT.0.0E0) PI(I)=180.0E0+PI(I)
   IF(FI(I).LE.0E0.AND.FR(I).GE.0.0E0) PI(I)=360.0E0+PI(I)
  ENDDO
 ENDIF
 RETURN
END SUBROUTINE


subroutine npow2(n,nfft,logn)
 implicit none
 integer*4::n,nfft,logn
 nfft=1
 logn=0
 do while(nfft.lt.n)
  nfft=2*nfft
  logn=logn+1
 enddo
 return
end subroutine


subroutine taper(data,n,width)
!仿照sac2000中的taper命令
!DATA(J)=DATA(J)*(F0-F1*COS(OMEGA*(J-1))
!======== ========= ===== ======
!TYPE     OMEGA     F0    F1
!======== ========= ===== ======
!HANNING   PI/N     0.50  0.50
!HAMMING   PI/N     0.54  0.46
!COSINE    PI/(2*N) 1.00  1.00
!======== ========= ===== ======
!这里选用HANNING
 implicit none
 integer*4::i,j,k,n,tl,tr
 real*4::data(n),width,f0,f1,omega
 real*4,parameter::pi=3.14159265358e0
 do i=1,n
  if(data(i).ne.0.0e0) exit
 enddo
 if(i.eq.n) return
 tl=i
 do i=n,1,-1
  if(data(i).ne.0.0e0) exit
 enddo
 tr=i
 f0=0.5e0
 f1=0.5e0
 j=anint((tr-tl+1)*width)
 omega=pi/j
 do i=tl,tl+j-1
  data(i)=data(i)*(f0-f1*cos(omega*(i-tl)))
 enddo
 do i=tr,tr-j+1,-1
  data(i)=data(i)*(f0-f1*cos(omega*(i-tr)))
 enddo
 return
end subroutine


subroutine nor(data,n)
 implicit none
 integer*4::n,i
 real*4::data(n),max
 max=0.0e0
 do i=1,n
  if(max.lt.abs(data(i))) max=abs(data(i))
 enddo
 if(max.eq.0.0e0) then
  print*, 'This is a zero data, please check'
  return
 endif
 data=data/max
 return
end subroutine


subroutine band(x,m,x0,xb,nerr)
 implicit none
 integer*4::xb,i,m,nerr
 real*4::x(m),x0
 nerr=0
 do i=1,m-1
  if((x(i)-x0)*(x(i+1)-x0).le.0.0e0) then
   if(abs(x0-x(i)).gt.abs(x0-x(i+1))) then
    xb=i+1
   else
    xb=i
   endif
   return
  endif
 enddo
 print*, 'The search point is not in the search range, please check'
 nerr=1
 return
end subroutine


subroutine seek(x,m,n,xb,yb,nerr)
!yb:输入输出
 implicit none
 integer*4::i,j,xb,yb,m,n,nerr
 real*4::x(0:m,0:n),a,b,c
 nerr=0
 do i=yb,2,-1
  a=x(i-1,xb)
  b=x(i,xb)
  c=x(i+1,xb)
  if(b.ge.a.and.b.ge.c) exit
 enddo
 do j=yb+1,m-1
  a=x(j-1,xb)
  b=x(j,xb)
  c=x(j+1,xb)
  if(b.ge.a.and.b.ge.c) exit
 enddo
 if(i.eq.2.and.j.eq.m-1) then
  print*, 'There is an error, please check'
  nerr=1
  return
 else if(i.eq.2.and.j.ne.m-1) then
  yb=j
  return
 else if(i.ne.2.and.j.eq.m-1) then
  yb=i
  return
 else if(abs(yb-i).le.abs(j-yb)) then
  yb=i
 else
  yb=j
 endif
 return
end subroutine


subroutine draw(data,m,n,xy,name,t0,v0)
!图示化功能实现,需要CPS3.30的库文件libcalpltf.a
 implicit none
 integer*4::i,m,n
 real*4::x(m),y(n),data(0:n,0:m),xy(m,6),temp(n),x0,y0,xnum,t0,v0
 real*4::xaxlen,firstx,deltax,yaxlen,firsty,deltay,dx,dy,hx,hy
 character*(*)::name
 character*60::pname
 pname=trim(name)//'.plt'
 x=data(0,1:m)
 y=data(1:n,0)
 call pinitf(pname)
 call gunit('in')
 call factor(0.9)
 xaxlen=9.0e0
 yaxlen=6.0e0
 firstx=x(1)
 deltax=(x(m)-x(1))/xaxlen
 firsty=y(n)
 deltay=(y(1)-y(n))/yaxlen
 dx=(x(m)-x(1))/(m-1)
 hx=abs(dx/(2*deltax))
 dy=abs((y(1)-y(n)))/(n-1)
 hy=dy/(2*deltay)
 call plot(0.5,0.5,-3)
 call gwrtxt(0.0,6.0,name,0)
 do i=1,m
  temp(1:n)=data(1:n,i)
  x0=(x(i)-x(1))/deltax
  y0=0.0e0
  xnum=xy(i,4)
  call putshd(x0,y0,temp,y,n,hx,firsty,deltay,i,m)
  !call putwave(x0,y0,temp,y,n,0.8*hx,firsty,deltay,xnum,i,m)
 enddo
 call putxy(xy,m,8,firstx,deltax,firsty,deltay,t0,v0)
 call axis(0.0,0.0,'Period/s',-8,xaxlen,0.0,firstx,deltax)
 call axis(0.0,0.0,'Phase Velocity/km*s-1',21,yaxlen,90.0,firsty,deltay)
 call graysc(9.5,0.0,0.5,yaxlen)
 call pend()
 return
end subroutine
  

subroutine putwave(x0,y0,x,y,n,hx,firsty,deltay,xnum,j,m)
 implicit none
 integer*4::i,j,xnum,n,m
 real*4::x(n),y(n),x0,y0
 real*4::amp,xx,yy,hx,firsty,deltay
 amp=-1.0e0
 do i=1,n
	if(amp.lt.abs(x(i))) amp=abs(x(i))
 enddo
 call plot(x0,y0,-3)
 do i=1,n
  xx=x(i)/amp*abs(hx)
  if(j.eq.1.and.xx.lt.0.0e0) xx=0.0e0
  if(j.eq.m.and.xx.gt.0.0e0) xx=0.0e0
  yy=(y(i)-firsty)/deltay
  if(i.eq.1)then
   call plot(xx,yy,3)
  else
   call plot(xx,yy,2)
  endif
  if(i.eq.xnum) then
   call newpen(1100)
   call symbol(xx-0.04,yy-0.08,0.1,'*',0.0,1)
   call newpen(1)
  endif
 enddo
 call plot(-x0,-y0,-3)
 return
end subroutine


subroutine putshd(x0,y0,x,y,n,hx,firsty,deltay,j,m)
 implicit none
 integer*4::n,i,j,ipen,m
 real*4::x(n),y(n),x0,y0,pen,ampmin,ampmax,amp
 real*4::xl,xh,y1,y2,y3,yl,yh,hx,firsty,deltay
 ampmin=1.0e+38
 ampmax=-1.0e+38
 do i=1,n
	if(ampmin.gt.x(i)) ampmin=x(i)
	if(ampmax.lt.x(i)) ampmax=x(i)
 enddo
 amp=ampmax-ampmin
 call plot(x0,y0,-3)
 do i=1,n
  xl=-hx
  xh=hx
  if(j.eq.1) xl=0.0e0
  if(j.eq.m) xh=0.0e0
  if(i.eq.1) then
   y1=(y(i)-firsty)/deltay
   y2=(y(i+1)-firsty)/deltay
   yl=y1
   yh=(y1+y2)/2
  elseif(i.eq.n) then
   y1=(y(i-1)-firsty)/deltay
   y2=(y(i)-firsty)/deltay
   yl=(y1+y2)/2
   yh=y2
  else
   y1=(y(i-1)-firsty)/deltay
   y2=(y(i)-firsty)/deltay
   y3=(y(i+1)-firsty)/deltay
   yl=(y1+y2)/2
   yh=(y2+y3)/2
  endif
  pen=1100-((x(i)-ampmin)/amp)*100
  if(pen.lt.1000.0e0) pen=1000.0e0
  if(pen.gt.1100.0e0) pen=1100.0e0
  ipen=floor(pen)
  !print*, ipen
!	ipen = 1000 is red, 1100 = blue or 1000 = dark, 1100 = light halftone
  call newpen(ipen)
  call shader(xl,yl,xh,yh,0,0,0.02,0.02)
 enddo
 call newpen(1)
 call plot(-x0,-y0,-3)
 return
end subroutine


subroutine putxy(x,m,n,firstx,deltax,firsty,deltay,t0,v0)
 implicit none
 integer*4::i,m,n
 real*4::x(m,n),xx,yy,firstx,deltax,firsty,deltay,t0,v0
 do i=1,m
  xx=(x(i,1)-firstx)/deltax
  yy=(x(i,3)-firsty)/deltay
  if(i.eq.1)then
   call plot(xx,yy,3)
  else
   call plot(xx,yy,2)
  endif
 enddo
 xx=(t0-firstx)/deltax
 yy=(v0-firsty)/deltay
 call symbol(xx,yy,0.1,'.',0.0,1)
 return
end subroutine


subroutine graysc(x0,y0,xlen,ylen)
 implicit none
 integer*4::i,ipinc,ipen
 real*4::x0,y0,xlen,ylen,dy,xl,xh,yl,yh,pen
 call plot(x0,y0,-3)
 call plot(0.0,ylen,2)
 call plot(xlen,ylen,2)
 call plot(xlen,0.0,2)
 call plot(0.0,0.0,2)
 ipinc=11
 dy=ylen/ipinc
 do i=1,ipinc
  xl=0.0e0
  xh=xlen
  yl=(i-1)*dy
  yh=i*dy
  pen=1100.0e0-(i-1)*100.0e0/(ipinc-1)
  ipen=anint(pen)
  call newpen(ipen)
  call shader(xl,yl,xh,yh,0,0,0.01,0.01)
  call newpen(1)
  call number(xh+0.1,yh-0.6*dy,0.1,0.1*(i-1),0.0,1)
 enddo
 call plot(-x0,-y0,-3)
 return
end subroutine


