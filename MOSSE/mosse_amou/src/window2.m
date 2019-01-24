% This function creates a 2 dimentional window for a sample image, it takes
% the dimension of the window and applies the 1D window function
% This is does NOT using a rotational symmetric method to generate a 2 window
%
% Disi A ---- May,16, 2013
%     [N,M]=size(imgage);
% ---------------------------------------------------------------------
%     w_type is defined by the following 
%     @bartlett       - Bartlett window.
%     @barthannwin    - Modified Bartlett-Hanning window. 
%     @blackman       - Blackman window.
%     @blackmanharris - Minimum 4-term Blackman-Harris window.
%     @bohmanwin      - Bohman window.
%     @chebwin        - Chebyshev window.
%     @flattopwin     - Flat Top window.
%     @gausswin       - Gaussian window.
%     @hamming        - Hamming window.
%     @hann           - Hann window.
%     @kaiser         - Kaiser window.
%     @nuttallwin     - Nuttall defined minimum 4-term Blackman-Harris window.
%     @parzenwin      - Parzen (de la Valle-Poussin) window.
%     @rectwin        - Rectangular window.
%     @taylorwin      - Taylor window.
%     @tukeywin       - Tukey window.
%     @triang         - Triangular window.
%
%   Example: 
%   To compute windowed 2D fFT
%   [r,c]=size(img);
%   w=window2(r,c,@hamming);
% 	fft2(img.*w);

%�Ӵ���Ҫ����ʱ���ڽ���(��ʱ���������,��Ƶ�����Ǿ������),����Ҫ�����Ǽ�С�����źŲü�������Ƶ��й¶.
%Ƶ��й¶ʹ�����ϵ͵����ߺ����ױ��ٽ��������ϸߵ����ߵ�й¶����ûס

function w=window2(N,M,w_func)

wr=window(w_func,N);%wrΪһά������,ά��Ϊheight x 1
wc=window(w_func,M);%wcΪһά������,ά��Ϊwidth x 1
% disp("wr")
% size(wr)
% disp("wc")
% size(wc)
[maskr,maskc]=meshgrid(wc,wr);%meshgrid�������ƶ�ά����ά����.maskr��maskc��ά��һ��,��Ϊheight x width
%[X,Y]=meshgrid(x,y)��������x��y�а��������귵�ض�ά�������ꡣX ��һ������,ÿһ����x��һ������;YҲ��һ������,ÿһ����y��һ������.����X��Y��ʾ��������length(y)���к�length(x)���С�
%maskc=repmat(wc,1,M); Old version
%maskr=repmat(wr',N,1);

% disp("maskr")
% size(maskr)
% disp("maskc")
% size(maskc)

w=maskr.*maskc;%������crop image��ͬά�ȵĴ� 
% disp("w")
% size(w)
end