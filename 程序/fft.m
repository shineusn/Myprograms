%                            FFT实践及频谱分析                          %
%*************************************************************************%
%*************************************************************************%
%***************1.正弦波****************%
fs=100;%设定采样频率
N=128;
n=0:N-1;
t=n/fs;
f0=10;%设定正弦信号频率
%生成正弦信号
x=sin(2*pi*f0*t);
figure(1);
subplot(231);
plot(t,x);%作正弦信号的时域波形
xlabel('t');
ylabel('y');
title('正弦信号y=2*pi*10t时域波形');
grid;
%进行FFT变换并做频谱图
y=fft(x,N);%进行fft变换
mag=abs(y);%求幅值
f=(0:length(y)-1)'*fs/length(y);%进行对应的频率转换
figure(1);
subplot(232);
plot(f,mag);%做频谱图
axis([0,100,0,80]);
xlabel('频率(Hz)');
ylabel('幅值');
title('正弦信号y=2*pi*10t幅频谱图N=128');
grid;
%求均方根谱
sq=abs(y);
figure(1);
subplot(233);
plot(f,sq);
xlabel('频率(Hz)');
ylabel('均方根谱');
title('正弦信号y=2*pi*10t均方根谱');
grid;
%求功率谱
power=sq.^2;
figure(1);
subplot(234);
plot(f,power);
xlabel('频率(Hz)');
ylabel('功率谱');
title('正弦信号y=2*pi*10t功率谱');
grid;
%求对数谱
ln=log(sq);
figure(1);
subplot(235);
plot(f,ln);
xlabel('频率(Hz)');
ylabel('对数谱');
title('正弦信号y=2*pi*10t对数谱');
grid;
%用IFFT恢复原始信号
xifft=ifft(y);
magx=real(xifft);
ti=[0:length(xifft)-1]/fs;
figure(1);
subplot(236);
plot(ti,magx);
xlabel('t');
ylabel('y');
title('通过IFFT转换的正弦信号波形');
grid;
%****************2.矩形波****************%
fs=10;%设定采样频率
t=-5:0.1:5;
x=rectpuls(t,2);
x=x(1:99);
figure(2);
subplot(231);
plot(t(1:99),x);%作矩形波的时域波形
xlabel('t');
ylabel('y');
title('矩形波时域波形');
grid;
%进行FFT变换并做频谱图
y=fft(x);%进行fft变换
mag=abs(y);%求幅值
f=(0:length(y)-1)'*fs/length(y);%进行对应的频率转换
figure(2);
subplot(232);
plot(f,mag);%做频谱图
xlabel('频率(Hz)');
ylabel('幅值');
title('矩形波幅频谱图');
grid;
%求均方根谱
sq=abs(y);
figure(2);
subplot(233);
plot(f,sq);
xlabel('频率(Hz)');
ylabel('均方根谱');
title('矩形波均方根谱');
grid;
%求功率谱
power=sq.^2;
figure(2);
subplot(234);
plot(f,power);
xlabel('频率(Hz)');
ylabel('功率谱');
title('矩形波功率谱');
grid;
%求对数谱
ln=log(sq);
figure(2);
subplot(235);
plot(f,ln);
xlabel('频率(Hz)');
ylabel('对数谱');
title('矩形波对数谱');
grid;
%用IFFT恢复原始信号
xifft=ifft(y);
magx=real(xifft);
ti=[0:length(xifft)-1]/fs;
figure(2);
subplot(236);
plot(ti,magx);
xlabel('t');
ylabel('y');
title('通过IFFT转换的矩形波波形');
grid;
%****************3.白噪声****************%
fs=10;%设定采样频率
t=-5:0.1:5;
x=zeros(1,100);
x(50)=100000;
figure(3);
subplot(231);
plot(t(1:100),x);%作白噪声的时域波形
xlabel('t');
ylabel('y');
title('白噪声时域波形');
grid;
%进行FFT变换并做频谱图
y=fft(x);%进行fft变换
mag=abs(y);%求幅值
f=(0:length(y)-1)'*fs/length(y);%进行对应的频率转换
figure(3);
subplot(232);
plot(f,mag);%做频谱图
xlabel('频率(Hz)');
ylabel('幅值');
title('白噪声幅频谱图');
grid;
%求均方根谱
sq=abs(y);
figure(3);
subplot(233);
plot(f,sq);
xlabel('频率(Hz)');
ylabel('均方根谱');
title('白噪声均方根谱');
grid;
%求功率谱
power=sq.^2;
figure(3);
subplot(234);
plot(f,power);
xlabel('频率(Hz)');
ylabel('功率谱');
title('白噪声功率谱');
grid;
%求对数谱
ln=log(sq);
figure(3);
subplot(235);
plot(f,ln);
xlabel('频率(Hz)');
ylabel('对数谱');
title('白噪声对数谱');
grid;
%用IFFT恢复原始信号
xifft=ifft(y);
magx=real(xifft);
ti=[0:length(xifft)-1]/fs;
figure(3);
subplot(236);
plot(ti,magx);
xlabel('t');
ylabel('y');
title('通过IFFT转换的白噪声波形');
grid;

