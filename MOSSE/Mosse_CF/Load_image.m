<<<<<<< HEAD
%调用函数读取图片帧，读取groundtruth数据
=======
%���ú�����ȡͼƬ֡����ȡgroundtruth����
>>>>>>> NOSSE
function [ground_truth,img_path,img_files]=Load_image(imgDir)
%     %% Read params.txt
%     params = readParams('params.txt');
	%% load video info
<<<<<<< HEAD
    sequence_path = [imgDir,'/'];%文件路径
    img_path = [sequence_path 'img/'];
    %% Read files 
    ground_rect = csvread([sequence_path 'groundtruth_rect.txt']);%序列中真实目标位置
    %%%%%%%%%%%%%%%%%%%%%%%%%
    % read all the frames in the 'imgs' subfolder
    dir_content = dir([sequence_path 'img/']);
    % skip '.' and '..' from the count
    n_imgs = length(dir_content)- 2 ;
    img_files = cell(n_imgs, 1);% 得到n_imgs行，1列的空元胞数组。MATLAB元胞数组（cell）可以将浮点型、字符型、结构数组等不同类型的数据放在同一个存储单元中。
    for ii = 1:n_imgs
        img_files{ii} = dir_content(ii+2).name;
    end
    %% get position and boxsize 读取groundtruth数据 
    if(size(ground_rect,2)==1)%一列
        error('please add "," in groundtruth');%x,y,w,h目标框大小
    else if(size(ground_rect,2)==4)%4列
        ground_truth=ground_rect;%x,y,w,h目标框大小
=======
    sequence_path = [imgDir,'\'];%�ļ�·��
    img_path = [sequence_path 'img\'];
    %% Read files 
    ground_rect = csvread([sequence_path 'groundtruth_rect.txt']);%��������ʵĿ��λ��
    %%%%%%%%%%%%%%%%%%%%%%%%%
    % read all the frames in the 'imgs' subfolder
    dir_content = dir([sequence_path 'img\']);
    % skip '.' and '..' from the count
    n_imgs = length(dir_content)- 2 ;
    img_files = cell(n_imgs, 1);% �õ�n_imgs�У�1�еĿ�Ԫ�����顣MATLABԪ�����飨cell�����Խ������͡��ַ��͡��ṹ����Ȳ�ͬ���͵����ݷ���ͬһ���洢��Ԫ�С�
    for ii = 1:n_imgs
        img_files{ii} = dir_content(ii+2).name;
    end
    %% get position and boxsize ��ȡgroundtruth���� 
    if(size(ground_rect,2)==1)%һ��
        error('please add "," in groundtruth');%x,y,w,hĿ����С
    else if(size(ground_rect,2)==4)%4��
        ground_truth=ground_rect;%x,y,w,hĿ����С
>>>>>>> NOSSE
    else
        error('something wrong in groundtruth');
        end
    end
<<<<<<< HEAD
%     im = imread([img_path img_files{1}]);%读取目标帧
%     im= rgb2gray(im);%转换为灰度图
=======
%     im = imread([img_path img_files{1}]);%��ȡĿ��֡
%     im= rgb2gray(im);%ת��Ϊ�Ҷ�ͼ
>>>>>>> NOSSE
%     imshow(im);
end