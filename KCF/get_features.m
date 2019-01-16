function x = get_features(im, features, cell_size, cos_window)
%GET_FEATURES
%   Extracts dense features from image.
%
%   X = GET_FEATURES(IM, FEATURES, CELL_SIZE)
%   Extracts features specified in struct FEATURES, from image IM. The
%   features should be densely sampled, in cells or intervals of CELL_SIZE.
%   The output has size [height in cells, width in cells, features].
%
%   To specify HOG features, set field 'hog' to true, and
%   'hog_orientations' to the number of bins.
%
%   To experiment with other features simply add them to this function
%   and include any needed parameters in the FEATURES struct. To allow
%   combinations of features, stack them with x = cat(3, x, new_feat).
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/


	if features.hog
		%HOG features, from Piotr's Toolbox
		x = double(fhog(single(im) / 255, cell_size, features.hog_orientations));%single - ����������,xΪ��õ�HOG������һ����ά����;����255��һ�����ܶԹ��ձ仯����Ӱ��ø��õ�Ч����
		x(:,:,end) = [];  %remove all-zeros channel ("truncation feature"�ض�����)%��Ϊ�ض����������㣬��˽��ض�����ȥ��
	end
	
	if features.gray
		%gray-level (scalar feature)
		x = double(im) / 255; %������ֵ��һ����0-1֮��
		
		x = x - mean(x(:));%��x��һ����(-0.5,0.5),����CSK�������
	end
	
	%process with cosine window if needed
	if ~isempty(cos_window)
		x = bsxfun(@times, x, cos_window);%bsxfun - ����������Ӧ�ð�Ԫ�����㣨������ʽ��չ��,@times-����˷�
	end
	
end
