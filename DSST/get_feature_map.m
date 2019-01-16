function out = get_feature_map(im_patch)

% allocate space
out = zeros(size(im_patch, 1), size(im_patch, 2), 28, 'single');

% if grayscale image
if size(im_patch, 3) == 1
    out(:,:,1) = single(im_patch)/255 - 0.5;
    temp = fhog(single(im_patch), 1);%����1��HOG��cell_size�Ĵ�С��KCF����ڻҶ�ͼ���õ���1������1��������1��cell
    out(:,:,2:28) = temp(:,:,1:27);
else
    out(:,:,1) = single(rgb2gray(im_patch))/255 - 0.5;
    temp = fhog(single(im_patch), 1);%����1��HOG��cell_size�Ĵ�С��KCF�����RGBͼ���õ���4������4��������1��cell,������1�ͻ���ɼ����������ٶ�����
    out(:,:,2:28) = temp(:,:,1:27);%temp���Ϊ32ά������ֻȡǰ27ά��
end
