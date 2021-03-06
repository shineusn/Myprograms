!This program is try to do the wiener filter.Input is T1.ASC,T2.ASC,which are the seismic data of station 1 and station 2.Output is G.TXT
!Author :Chen Haopeng
!Creatied:2010.05.14
!modified 2010.05.24
PROGRAM MAIN
INTEGER,PARAMETER::M=1653,N=900,K=2552
!N represent the number of pionts read in from station1, M is the number of wiener filter coeff.K represent the number of pionts read in from station2
! K=M+N-1
REAL*8::T1(N),T2(K),H(N),T(M),D(M),G(M)
OPEN(10,FILE='1LHZ.sac.asc')
OPEN(11,FILE='2BHZ.TXT')
  DO I=1,30
    READ(10,*)
  END DO
  DO I=1,430/5
    READ(10,*)
  END DO
  DO I=1,N/5
     READ(10,*) T1((I-1)*5+1),T1((I-1)*5+2),T1((I-1)*5+3),T1((I-1)*5+4),T1((I-1)*5+5)
  END DO
  DO I=1,K
     READ(11,*) T2(K)
  END DO

 CLOSE(10)
 CLOSE(11)
  CALL COR(T1,N,T1,N,T,M)
    CALL COR(T2,K,T1,N,D,M)
  CALL TOEP(T,M,D,G)
OPEN(12,FILE='G.TXT') !G.TXT保存的是滤波器序列
   DO I=1,M
      WRITE(12,*) G(I)
   END DO
 CLOSE(12)
END PROGRAM

!This program is purposed to calculate the auto-correlation or 
!corss-correlation function
!creatied 2010.05.13   

   SUBROUTINE COR(X,M,H,N,Y,L)
   REAL*8::X(M),H(N),Y(L)
!注意X(M),H(N)为输入，Y(L)为X(M)与H(N)相关序列的0-L-1项
   DO 10 K=1,L
      Y(K)=0.0
      DO 20 I=1,N
         IF(K+I.LE.M+1) Y(K)=Y(K)+H(I)*X(K+I-1)
      !注意书上的公式似乎错了
20    CONTINUE
10 CONTINUE
   END SUBROUTINE 


!This program is use the Levinson recursion algorithm to solve the filter equation with Toeplitz 
!matrix 
!from book 地震数据处理方法 李振春 张军华 page63-64
!creatied 2010.05.13
SUBROUTINE TOEP(T,N,B,X)
DIMENSION T(N),B(N),X(N),Y(N),S(N)
DOUBLE PRECISION T,B,X,Y,S,A,C,H,Q,BETA
!T(N)为输入的托布里兹矩阵元素，即为自相关函数的前N项；B(N)为方程右端相，即为互相关函数的前N项
!X(N)为所求解，即滤波因子h(t);Y(N)与S(N)为中间数组
L=1
A=T(1)  
!T(1)对应r(0)
IF(ABS(A).EQ.0) THEN
   L=0
   WRITE(*,100)
   RETURN
END IF
100 FORMAT(1X,'FAIL')
!上面是说当T(1)=0时，方程无解，输出错误信息
Y(1)=1.0
X(1)=B(1)/T(1) !T(1)不为0时，求出X(1)的初值。注意：最终的X(1）并不
!一定是这样的。
!接下来递归求解X(K),K=1,N
DO 40 K=1,N-1
   BETA=0.0
   Q=0.0
   DO 10 J=1,K
      BETA=BETA+Y(J)*T(J+1)
      Q=Q+X(J)*T(K-J+2)
10 CONTINUE
   IF(ABS(A).EQ.0)THEN
     L=0
     WRITE(*,100)
     RETURN
   ENDIF
   C=-BETA/A
   S(1)=C*Y(K)
   Y(K+1)=Y(K)
   IF(K.NE.1) THEN
      DO 20 I=2,K
20    S(I)=Y(I-1)+C*Y(K-I+1)
   ENDIF
   A=A+C*BETA
   IF(ABS(A).EQ.0) THEN
      L=0
      WRITE(*,100)
      RETURN
   ENDIF
   H=(B(K+1)-Q)/A
   DO 30 I=1,K
      X(I)=X(I)+H*S(I)
      Y(I)=S(I)
30 CONTINUE
   X(K+1)=H*Y(K+1)
40 CONTINUE
END SUBROUTINE 


