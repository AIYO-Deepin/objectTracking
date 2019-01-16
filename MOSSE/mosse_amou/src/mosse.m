clear ;clc
% get images from source directory
datadir = 'D:\\objectTracking\\configSeqs\\OTB-100';
dataset = 'RedTeam';
path = [datadir '\\' dataset];
img_path = [path '\\img\\'];
D = dir([img_path, '*.jpg']); % return a list of all the files in the current path and the folders
seq_len = length(D(not([D.isdir]))); % if files in the D are folders, isdir=1, otherwise isdir=0. 
if exist([img_path num2str(1, '%04i.jpg')], 'file') % Is there  a file named img_path/0001.jpg?
    img_files = num2str((1:seq_len)', [img_path '%04i.jpg']);%numstr�Ƚ����⣬��'\��ĸ'��Ϊ�����ַ�������Ҫ����'\\��ĸ'�������ΪʲôdatadirΪ'\\'
else
    error('No image files found in the directory.');
end

% select target from first frame
im = imread(img_files(1,:));
f = figure('Name', 'Select object to track'); %figure��name����Ϊ'Select object to track'
imshow(im);
rect = getrect; %getrectʹ������ڵ�ǰ����ѡ��һ������,rect���ص��Ǿ������Ͻ�����,���ο�Ŀ�Ⱥ͸߶�(x,y,width,height)
                %��������Լ��Ϊ����,ʹ��shift���Ҽ�������ʼ�϶�.
close(f); clear f; %�ڵ�һ֡�ϻ������κ�,ȡ�þ��ο���Ϣ,Ȼ��رյ�һ֡ͼ��
center = [rect(1)+rect(3)/2 rect(2)+rect(4)/2];%�����þ��ε�����������ͼ���ϵ�width,height

% plot gaussian
sigma = 10;
a = 10;
gsize = size(im);%���image���ص�(row*column*channel)
[R,C] = ndgrid(1:gsize(1), 1:gsize(2));%R��C��Ϊgsize(1)��,gsize(2)��,����RΪ��1Ϊ����,��1��gsize(1)����������,CΪ��1��gsize(2)����������
g = gaussC(C,R, sigma, a, center);
g = mat2gray(g);%��ͼ�����g��һ��Ϊͼ�����g����һ���������ÿ��Ԫ�ص�ֵ����0��1��Χ�ڣ�����0��1),����0��ʾ��ɫ,255��ʾ��ɫ.

% randomly warp original image to create training set
if (size(im,3) == 3) %image channel
    img = rgb2gray(im); %��ͼƬ��rgb��Ϊgray
end
img = imcrop(img, rect);%cropԭʼͼ��,imcropͼ���������,RECTΪ��ѡ��������ʽΪ[XMIN YMIN WIGTH HEIGHT].
g = imcrop(g, rect);%crop gauss image
G = fft2(g);%��ά���ٸ���Ҷ�任,��ʱ������תΪƵ������,�õ������źŵķ���Ƶ��.
            %һά�ź�(�������ź�)��fft,��ά�ź�(��ͼ���ź�)��fft2
            %����Ҷ�任�Ļ���˼����:�κ�����������ʱ����źţ������Ա�ʾΪ��ͬƵ�ʵ����Ҳ��źŵ����޵���(����ǵ��źſ��Ա����޽ӽ�).
height = size(g,1);%ȡ������ͼ��g��height
width = size(g,2);%ȡ������ͼ��g��width
fi = preprocess(imresize(img, [height width]));%imresize����ͼ������imresize(A, [numrows numcols]),numrows��numcols�ֱ�ָ��Ŀ��ͼ��ĸ߶ȺͿ�ȡ�
                                               %imresize ʹ��˫���η���ֵ����ʵ�ֵ�ͼƬ���š�
                                               %�Զ��׼�,�������ָ�ʽ����ͼ�����ź󳤿������Դͼ�񳤿��������ͬ,�����������ͼ���п��ܷ������䡣
Ai = (G.*conj(fft2(fi)));%conj���������ڼ��㸴���Ĺ���ֵ
Bi = (fft2(fi).*conj(fft2(fi)));
% N = 128;
% %�������forѭ������˼Ӧ����ͨ������,����ϵͳ³����,����ֻ�ڵ�һ֡����,�������л���ǰ���ݽ�������,�������������岻��.�����ҽ�ÿһ֡���������ֲ���,
  % ʱ���ϱ�÷ǳ���,��������rand_warp����ֻ������ת����,�����������β�δ���д���,�����Surfer���ݼ��е�����������������ֱʱ,���׳��ָ���ʧ��.
% for i = 1:N
%     fi = preprocess(rand_warp(img));
%     Ai = Ai + (G.*conj(fft2(fi)));
%     Bi = Bi + (fft2(fi).*conj(fft2(fi)));
% end
% Ai = Ai / N;
% Bi = Bi / N; 
% MOSSE online training regimen
eta = 0.125;
fig = figure('Name', 'MOSSE');%��ͼ��nameΪMOSSE
% mkdir(['results_' dataset]);%�����ļ��������������ɵĴ����ٿ��ͼ��
time = clock;
for i = 1:size(img_files, 1) %����ȡ������ͼƬ
    img = imread(img_files(i,:));
    im = img;
    if (size(img,3) == 3) %��Ϊ�Ҷ�ͼ��
        img = rgb2gray(img);
    end
    if (i == 1)
        Ai = eta.*Ai;
        Bi = eta.*Bi;
    else
        try
            Hi = Ai ./ Bi;%��Ӧ���
            fi = imcrop(img, rect); 
            fi = preprocess(imresize(fi, [height width]));%�����ͼ֮��ֱ�Ӷ���֡��ͼ����мӴ�����˵�����Ƶ��й¶���⣬����Ҳ����֡������һ֡������λ��
                                                          %ͻ���ˣ��������Ⲣ���ǵ�ǰ֡������λ�ã���˻����Ư�ơ�
            gi = uint8(255*mat2gray(real(ifft2(Hi.*fft2(fi)))));%mat2gray�������һ��.realȡ����ʵ��,imagȡ�����鲿.ifft2���ٸ���Ҷ���任
                                                                %�����һ��Ȼ�����255��ת����8λ����,����Ϊ8λͼ����ֵΪ0-255.
            maxval = max(gi(:)); %ȡ��gi���������ֵ
            [P, Q] = find(gi == maxval);%ȡ��gi���������ֵ���ڵ�λ��,P=row,Q=column
            dx = mean(Q)-width/2;%�õ���N֡ͼ�����N-1֡ͼ��Ա����ӵ�dx��dy
            dy = mean(P)-height/2;

            rect = [rect(1)+dx rect(2)+dy width height];%�������ο�λ��,�Եõ����µ����ֵλ����Ϊ���ο�����,
            fi = imcrop(img, rect); %���½�ͼ
            fi = preprocess(imresize(fi, [height width]));%���½�ͼ�Ӵ�
    %         Ci = G.*conj(fft2(fi));
    %         Di = fft2(fi).*conj(fft2(fi));
    %         for j = 1:N
    %             fi = preprocess(rand_warp(fi));
    %             Ci = Ci+ (G.*conj(fft2(fi)));
    %             Di = Di + (fft2(fi).*conj(fft2(fi)));
    %         end
    %         Ai = eta.*(Ci) + (1-eta).*Ai;
    %         Bi = eta.*(Di) + (1-eta).*Bi;

            Ai = eta.*(G.*conj(fft2(fi))) + (1-eta).*Ai;%�����ĸ���Ai��Bi
            Bi = eta.*(fft2(fi).*conj(fft2(fi))) + (1-eta).*Bi;
        catch
            return
        end
    end
    
    % visualization
    text_str = ['Frame: ' num2str(i)];%����ʾ��ͼ����Ҫ��ʾ����������
    box_color = 'green';%��ʾ���ֵı�������ɫ
    position=[1 1];%��ʾ���ֱ��������Ͻ�����,���С������ʾ�����ݸı�
    result = insertText(im, position,text_str,'FontSize',15,'BoxColor',box_color,'BoxOpacity',0.4,'TextColor','white');
    %insertText:insert tex in image or video,return the processed image or video-BoxOpacity:�ı���͸����
    %insertShape:Insert shapes in image or video
    result = insertShape(result, 'Rectangle', rect, 'LineWidth', 3);
%     imwrite(result, ['results_' dataset num2str(i, '/%04i.jpg')]);%����ͼ��
    imshow(result);
end
disp(['Frames-per-second: ' num2str(seq_len / etime(clock,time))])
