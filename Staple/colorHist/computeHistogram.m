function histogram = computeHistogram(patch, mask, n_bins, grayscale_sequence)
%COMPUTEHISTOGRAM creates a colour (or grayscale) histogram of an image patch
% MASK has the same size as the image patch and selects what should
% be used when computing the histogram (i.e. out-of-frame regions are ignored)

	[h, w, d] = size(patch);

	assert(all([h w]==size(mask)) == 1, 'mask and image are not the same size');%��getSubwindow�������Ե�֪all([h w]==size(mask)���ǳ�����

	bin_width = 256/n_bins;%params�в���ȡn_bins=2^5,��ô����bin_width = 8��Ҳ����ֱ��ͼ�Ŀ��Ϊ8��һ��2^5��ֱ��ͼ

	% convert image to 1d array with same n channels of img patch
	patch_array = reshape(double(patch), w*h, d);%����ά��ɶ�ά��Ҳ����ÿһ����һ�����ص��RGB
	% compute to which bin each pixel (for all 3 channels) belongs to%����ÿ�����أ���������3��ͨ���������ĸ�bin
	bin_indices = floor(patch_array/bin_width) + 1;%ÿ8������Ϊһ��ֱ��ͼ����patch��ÿ����������32��ֱ��ͼ�е���һ��ֱ��ͼ

	if grayscale_sequence
		histogram = accumarray(bin_indices, mask(:), [n_bins 1])/sum(mask(:));%accumarray-ʹ���ۼӹ�������
	else
		% the histogram is a cube of side n_bins
		histogram = accumarray(bin_indices, mask(:), [n_bins n_bins n_bins])/sum(mask(:));%��maskΪbg_mask����ͳ�Ʊ�������ɫֱ��ͼ������sum(msk(:))Ϊ��һ��
                                                                                          %ͬʱָ������ľ����ʽΪ32*32*32ά��û��ֵ��λ����0����
                                                                                          %bin_indicesά���У�Ҳ����ÿһ�����ص��RGB
                                                                                          %����bin_indices��һ��Ϊ[2,5,7]����mask(:)�ж�Ӧ��ֵ�ۼӵ�
                                                                                          %��2��5��7��λ�á�
	end

end
