<<<<<<< HEAD
%%%%%%%%%%%%%%%%%%%%产生高斯理想响应%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function F_response=templateGauss(sz,im)
    [rs, cs] = ndgrid((1:sz(1)) - floor(sz(1)/2), (1:sz(2)) - floor(sz(2)/2));%中心点的数值为(0 0)
    dist = rs.^2 + cs.^2;%所有数值非负
    conf = exp(-0.5 / (2.25) * sqrt(dist));%生成二维高斯分布
    conf = conf/sum(sum(conf));% normalization
%由前面代码可知，im已经转成灰度图像，因此这里的这个判断没意义
%     if(size(im,3)==1)%灰度图像 
=======
%%%%%%%%%%%%%%%%%%%%������˹������Ӧ%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function F_response=templateGauss(sz,im)
    [rs, cs] = ndgrid((1:sz(1)) - floor(sz(1)/2), (1:sz(2)) - floor(sz(2)/2));%���ĵ����ֵΪ(0 0)
    dist = rs.^2 + cs.^2;%������ֵ�Ǹ�
    conf = exp(-0.5 / (2.25) * sqrt(dist));%���ɶ�ά��˹�ֲ�
    conf = conf/sum(sum(conf));% normalization
%��ǰ������֪��im�Ѿ�ת�ɻҶ�ͼ��������������ж�û����
%     if(size(im,3)==1)%�Ҷ�ͼ�� 
>>>>>>> NOSSE
%         response=conf;
%     else
%         response(:,:,1)=conf;
%         response(:,:,2)=conf;
%         response(:,:,3)=conf;    
%     end       
% %         figure
% %         imshow(256.*response);
% %         mesh(response);
<<<<<<< HEAD
        F_response=fft2(conf);%傅里叶变换
=======
        F_response=fft2(conf);%����Ҷ�任
>>>>>>> NOSSE
end