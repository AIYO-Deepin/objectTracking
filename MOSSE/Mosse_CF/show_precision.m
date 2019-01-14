function show_precision(positions, ground_truth, title)
%SHOW_PRECISION
%   Calculates precision for a series of distance thresholds (percentage of
%   frames where the distance to the ground truth is within the threshold).
%   The results are shown in a new figure.
%
%   Accepts positions and ground truth as Nx2 matrices (for N frames), and
%   a title string.
%
<<<<<<< HEAD
%   Jo�o F. Henriques, 2012
=======
%   Jo?o F. Henriques, 2012
>>>>>>> NOSSE
%   http://www.isr.uc.pt/~henriques/

	
	max_threshold = 50;  %used for graphs in the paper
	
	
<<<<<<< HEAD
	if size(positions,1) ~= size(ground_truth,1) %~= 是不等于号
=======
	if size(positions,1) ~= size(ground_truth,1) %~= �ǲ����ں�
>>>>>>> NOSSE
		disp('Could not plot precisions, because the number of ground')
		disp('truth frames does not match the number of tracked frames.')
		return
	end
	%%
    target_sz = [ground_truth(:,4), ground_truth(:,3)];
<<<<<<< HEAD
	pos = [ground_truth(:,2), ground_truth(:,1)] + floor(target_sz/2);%第一帧位置的像素值
	%% calculate distances to ground truth over all frames
	distances = sqrt((positions(:,1) - pos(:,1)).^2 + ...
				 	 (positions(:,2) - pos(:,2)).^2);
	distances(isnan(distances)) = []; %无穷大的距离为[]
=======
	pos = [ground_truth(:,2), ground_truth(:,1)] + floor(target_sz/2);%��һ֡λ�õ�����ֵ
	%% calculate distances to ground truth over all frames
	distances = sqrt((positions(:,1) - pos(:,1)).^2 + ...
				 	 (positions(:,2) - pos(:,2)).^2);
	distances(isnan(distances)) = []; %�����ľ���Ϊ[]
>>>>>>> NOSSE

	%compute precisions
	precisions = zeros(max_threshold, 1);
	for p = 1:max_threshold
<<<<<<< HEAD
		precisions(p) = nnz(distances < p) / numel(distances);%nnz(x):返回矩阵X中的非零元素的数目;nnz(X)/prod(size(X)):稀疏矩阵的密度是
=======
		precisions(p) = nnz(distances < p) / numel(distances);%nnz(x):���ؾ���X�еķ���Ԫ�ص���Ŀ;nnz(X)/prod(size(X)):ϡ�������ܶ���
>>>>>>> NOSSE
	end
	
	%plot the precisions
	figure( 'Name',['Precisions - ' title])
	plot(precisions, 'k-', 'LineWidth',2)
    grid on
	xlabel('Threshold'), ylabel('Precision')

end

