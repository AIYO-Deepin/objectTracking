% This function implements the SRDCF tracker.

function results = SRDCF_tracker(params)

% parameters
search_area_scale = params.search_area_scale;%��������ΪĿ���С��4��
output_sigma_factor = params.output_sigma_factor;%һ��Ϊ1/16����1/10
lambda = params.lambda;
learning_rate = params.learning_rate;
refinement_iterations = params.refinement_iterations;
filter_max_area = params.filter_max_area;
nScales = params.number_of_scales;
scale_step = params.scale_step;
interpolate_response = params.interpolate_response;
num_GS_iter = params.num_GS_iter;

features = params.t_features;

s_frames = params.s_frames;
pos = floor(params.init_pos);
target_sz = floor(params.wsize);

debug = params.debug;
visualization = params.visualization || debug;

num_frames = numel(s_frames);

init_target_sz = target_sz;

%set the feature ratio to the feature-cell size����HOG��cell_sizeһ�£�Ҳ����HOG�Ὣʹ��4x4��cell_size,��ôlableҲ�ͱ���ͬ���Ľ�����С��
featureRatio = params.t_global.cell_size;

search_area = prod(init_target_sz / featureRatio * search_area_scale); %prod - ����Ԫ�صĳ˻�

% when the number of cells are small, choose a smaller cell size
if isfield(params.t_global, 'cell_selection_thresh')%isfield - ȷ�������Ƿ�Ϊ�ṹ�������ֶ�
    if search_area < params.t_global.cell_selection_thresh * filter_max_area%�������������˲��������0.75^2С����ô����ʹ�ý�������
        params.t_global.cell_size = min(featureRatio, max(1, ceil(sqrt(prod(init_target_sz * search_area_scale)/(params.t_global.cell_selection_thresh * filter_max_area)))));
        
        featureRatio = params.t_global.cell_size;
        search_area = prod(init_target_sz / featureRatio * search_area_scale);%��֤���������㹻��
    end
end

global_feat_params = params.t_global;

if search_area > filter_max_area%ʹ���˲������������������˲�����������ȡ�߶���������
    currentScaleFactor = sqrt(search_area / filter_max_area);
else
    currentScaleFactor = 1.0;
end

% target size at the initial scale
base_target_sz = target_sz / currentScaleFactor;

%window size, taking padding into account
switch params.search_area_shape
    case 'proportional'
        sz = floor( base_target_sz * search_area_scale);     % proportional area, same aspect ratio as the target
    case 'square'
        sz = repmat(sqrt(prod(base_target_sz * search_area_scale)), 1, 2); % square area, ignores the target aspect ratio %repmat - �ظ����鸱��,����1��2������
    case 'fix_padding'
        sz = base_target_sz + sqrt(prod(base_target_sz * search_area_scale) + (base_target_sz(1) - base_target_sz(2))/4) - sum(base_target_sz)/2; % const padding
    otherwise
        error('Unknown "params.search_area_shape". Must be ''proportional'', ''square'' or ''fix_padding''');
end

% set the size to exactly match the cell size
sz = round(sz / featureRatio) * featureRatio;%round - ��������Ϊ���������
use_sz = floor(sz/featureRatio);%use_szΪ����

% construct the label function
output_sigma = sqrt(prod(floor(base_target_sz/featureRatio))) * output_sigma_factor;%label�Ĵ���
rg = circshift(-floor((use_sz(1)-1)/2):ceil((use_sz(1)-1)/2), [0 -floor((use_sz(1)-1)/2)]);
cg = circshift(-floor((use_sz(2)-1)/2):ceil((use_sz(2)-1)/2), [0 -floor((use_sz(2)-1)/2)]);
[rs, cs] = ndgrid( rg,cg);
y = exp(-0.5 * (((rs.^2 + cs.^2) / output_sigma^2)));
yf = fft2(y);

if interpolate_response == 1%��ֵ��Ӧ
    interp_sz = use_sz * featureRatio;
else
    interp_sz = use_sz;
end

% construct cosine window
cos_window = single(hann(use_sz(1))*hann(use_sz(2))');

% the search area size���������С
support_sz = prod(use_sz);

% Calculate feature dimension
im = imread(s_frames{1});
if size(im,3) == 3
    if all(all(im(:,:,1) == im(:,:,2)))
        colorImage = false;
    else
        colorImage = true;
    end
else
    colorImage = false;
end

% compute feature dimensionality %����ά�ȣ���ʹ��hog��gray��������������Ҫ��������ά�ȱ�Ϊ����ά��֮��
feature_dim = 0;
for n = 1:length(features)%����features�Ľṹ�峤��Ϊ2��ѭ��֮����õ�feature_dim=32Ϊ�Ҷȵļ���HOG��31.
    
    if ~isfield(features{n}.fparams,'useForColor')
        features{n}.fparams.useForColor = true;
    end
    
    if ~isfield(features{n}.fparams,'useForGray')
        features{n}.fparams.useForGray = true;
    end
    
    if (features{n}.fparams.useForColor && colorImage) || (features{n}.fparams.useForGray && ~colorImage)
        feature_dim = feature_dim + features{n}.fparams.nDim;
    end
end

if size(im,3) > 1 && colorImage == false
    im = im(:,:,1);
end

% compute the indices for the real, positive and negative parts of the
% spectrum
[dft_sym_ind, dft_pos_ind, dft_neg_ind] = partition_spectrum2(use_sz);%real,positive��negative parts���±꣬�������е�g_0,g+,g-
                                                   %g_0=[1,26,1251,1276]' ,g+=[2:25, 51:1250, 1252:1275]' , g-=[27:50,1277:2500]'                                           
% the discrete fourier series output indices(�±�)  dfs-discrete fourier
% series(��ɢ����Ҷ����),dft-discrete fourier transform(��ɢ����Ҷ�任)
dfs_sym_ind = (1:length(dft_sym_ind))';
dfs_real_ind = dfs_sym_ind(end) - 1 + 2 * (1:length(dft_pos_ind))';%����
dfs_imag_ind = dfs_sym_ind(end) + 2 * (1:length(dft_pos_ind))';%ż��

% construct the transformation matrix from dft to dfs (the real fourier
% series)
dfs_matrix = dft2dfs_matrix(dft_sym_ind, dft_pos_ind, dft_neg_ind, dfs_sym_ind, dfs_real_ind, dfs_imag_ind);%���ϡ�����2500x2500

% create vectorized desired correlation output������
yf_vec = single(yf(:));%single - ���������顣MATLAB �еĵ����ȱ����洢Ϊ single �������ͣ��ࣩ�� 4 ���ֽڣ�32 λ������ֵ

if params.use_reg_window
    % create weight window
    ref_window_power = params.reg_window_power;
    
    % normalization factor
    reg_scale = 0.5 * base_target_sz/featureRatio;
    
    % construct grid
    wrg = -(use_sz(1)-1)/2:(use_sz(1)-1)/2;
    wcg = -(use_sz(2)-1)/2:(use_sz(2)-1)/2;%�Գ�����ṹ
    [wrs, wcs] = ndgrid(wrg, wcg);
    
    % construct the regukarization window
    reg_window = (params.reg_window_edge - params.reg_window_min) * (abs(wrs/reg_scale(1)).^ref_window_power + abs(wcs/reg_scale(2)).^ref_window_power) + params.reg_window_min;
    
    % compute the DFT and enforce sparsity
    reg_window_dft = fft2(reg_window) / prod(use_sz);%ת�ɸ���Ҷ��ʽ��ͬʱ��һ��
    reg_window_dft_sep = cat(3, real(reg_window_dft), imag(reg_window_dft));%��reg_window_dft��ʵ�����鲿�����������ڵ�����ά���ϵ���
    reg_window_dft_sep(abs(reg_window_dft_sep) < params.reg_sparsity_threshold * max(abs(reg_window_dft_sep(:)))) = 0;%С�ھ��ȵ�ֱ������Ϊ0��ϡ�軯����С����.�������������ֱ�Ϊ0
    reg_window_dft = reg_window_dft_sep(:,:,1) + 1i*reg_window_dft_sep(:,:,2);%��������ά���ϵĵ�2���ָ�Ϊ����
    
    % do the inverse transform, correct window minimum
    reg_window_sparse = real(ifft2(reg_window_dft));%����Ҷ��任
    reg_window_dft(1,1) = reg_window_dft(1,1) - support_sz * min(reg_window_sparse(:)) + params.reg_window_min;%reg_window_dft(1,1)Ϊ���ֵ��λ��
    
    % construct the regularizsation matrix
    regW = cconvmtx2(reg_window_dft);%ѭ������2500x2500,�������������ƶ���ͼ��,regWΪ����ĶԽ����
    
    regW_dfs = real(dfs_matrix * regW * dfs_matrix');
    
    WW_block = regW_dfs' * regW_dfs;%�����е�(W^T)W
    
    % If the filter size is small enough, remove small values in WW_block.
    % It takes too long time otherwise.ȥ��Сֵ����ʡʱ��
    if support_sz <= 120^2
        WW_block(0<abs(WW_block) & abs(WW_block)<0.00001) = 0;
    end
else
    % else use a scaled identity matrix��ֱ��ʹ����ͨ������
    WW_block = lambda * speye(support_sz);
    params.reg_window_min = sqrt(lambda);
end

% create block diagonal regularization matrix
WW = eval(['blkdiag(WW_block' repmat(',WW_block', 1, feature_dim-1) ');']);%eval - ִ���ı��е� MATLAB ���ʽ,repmat - �ظ����鸱��

% upper and lower triangular parts of the regularization matrix
WW_L = tril(WW);%tril - ������������β���
WW_U = triu(WW, 1);%triu - ������������β���

if nScales > 0%ʹ�õ�SAMF�ĳ߶Ƚ�������7����ѡֵ
    scale_exp = (-floor((nScales-1)/2):ceil((nScales-1)/2));
    
    scaleFactors = scale_step .^ scale_exp;
    
    %force reasonable scale changes
    min_scale_factor = scale_step ^ ceil(log(max(5 ./ sz)) / log(scale_step));
    max_scale_factor = scale_step ^ floor(log(min([size(im,1) size(im,2)] ./ base_target_sz)) / log(scale_step));
end

num_sym_coef = length(dft_sym_ind);

% create indexing vectors

% first create the indices for the symmetric (real) part of the spectrum
index_i_sym = zeros(2*feature_dim, length(dft_sym_ind), feature_dim);
index_j_sym = zeros(size(index_i_sym));

index_i_sym_re = repmat(bsxfun(@plus, support_sz*(0:feature_dim-1)', 1:length(dft_sym_ind)), [1 1 feature_dim]); %index for the Real-Real part
index_i_sym(1:2:end, :, :) = index_i_sym_re;%��2������
index_i_sym(2:2:end, :, :) = NaN; % these will be zero

index_j_sym_re = permute(index_i_sym_re, [3 2 1]);%permute - �������� N ά�����ά��
index_j_sym(1:2:end, :, :) = index_j_sym_re;
index_j_sym(2:2:end, :, :) = NaN; % these will be zero

% create the indices for the remaining part
index_i = zeros(2*feature_dim, 2*length(dft_pos_ind), feature_dim);
index_j = zeros(size(index_i));

index_i_re = repmat(bsxfun(@plus, support_sz*(0:feature_dim-1)', (length(dft_sym_ind)+1:2:support_sz)), [1 1 feature_dim]); %index for the Real-Real part
index_i(1:2:end, 1:2:end, :) = index_i_re;
index_i(2:2:end, 1:2:end, :) = index_i_re + 1;
index_i(1:2:end, 2:2:end, :) = index_i_re;
index_i(2:2:end, 2:2:end, :) = index_i_re + 1;

index_j_re = permute(index_i_re, [3 2 1]);
index_j(1:2:end, 1:2:end, :) = index_j_re;
index_j(2:2:end, 1:2:end, :) = index_j_re;
index_j(1:2:end, 2:2:end, :) = index_j_re + 1;
index_j(2:2:end, 2:2:end, :) = index_j_re + 1;

% concatenate the results,���ӽ��
index_i = cat(2, index_i_sym, index_i);
index_j = cat(2, index_j_sym, index_j);

index_i = index_i(:);%���һ��
index_j = index_j(:);

% the imaginary part of the autocorrelations (along the diagonal) will be
% zero�����������ֱ�Ϊ0
zero_ind = (index_i == index_j-1) | (index_i == index_j+1);
index_i(zero_ind) = NaN;
index_j(zero_ind) = NaN;

% indexing masks for upper and lower triangular part
data_L_mask = index_i >= index_j;
data_U_mask = index_i < index_j;

data_L_i = index_i(data_L_mask);%data_L_maskΪlogical���飬��Ϊ1ʱ��ȡ��ֵ����Ϊ0ʱ����ȡֵ
data_L_j = index_j(data_L_mask);
data_U_i = index_i(data_U_mask);
data_U_j = index_j(data_U_mask);

% extract the linear indeces(ָ��) from the data matrix and regularization matrix
WW_L_ind = find(WW_L);%���������ǲ����±�
data_L_ind = sub2ind(size(WW_L), data_L_i, data_L_j);%ת���±�

% compute the linear indeces of the non-zeros in the matrix
[L_ind, ~, data_WW_in_L_index] = unique([data_L_ind; WW_L_ind]);%����Ψһֵ����������Ҳ����ȥ���ظ�ֵ����������ȥ��0��L_indΪΨһֵ��
                                                                %��data_WW_in_L_indexΪԭ������L_ind�ĽǱ�ţ�������Կ�unique�����Ľ���

% compute the corresponding indices for the values in the data and reg
% matrix
data_in_L_index = uint32(data_WW_in_L_index(1:length(data_L_ind)));%��������Ψһֵ�ĽǱ�
WW_in_L_index = data_WW_in_L_index(length(data_L_ind)+1:end);%����Ǳ�

% create the arrays of values in the regularization matrix
nnz_L = length(L_ind);
WW_L_vec = zeros(nnz_L, 1, 'single');
WW_L_vec(WW_in_L_index) = full(WW_L(WW_L_ind));%full - ��ϡ�����ת��Ϊ������

% precompute the data part of the regularization matrix
WW_L_vec_data = WW_L_vec(data_in_L_index);%Ԥ����WW,����Ҳ�ᵽ����Ԥ����

% initialize the content vectors for the matrices
L_vec = WW_L_vec;

% preallocate the matrices
mat_size = feature_dim * support_sz;
[L_i, L_j] = ind2sub(size(WW_L), L_ind);
AL = sparse(L_i, L_j, ones(nnz_L,1), mat_size, mat_size);
AU_data = sparse(data_U_i, data_U_j, ones(length(data_U_i),1), mat_size, mat_size);

if interpolate_response >= 3%ʹ��ţ�ٷ���ֵ
    % Pre-computes the grid that is used for socre optimization
    ky = circshift(-floor((use_sz(1) - 1)/2) : ceil((use_sz(1) - 1)/2), [1, -floor((use_sz(1) - 1)/2)]);
    kx = circshift(-floor((use_sz(2) - 1)/2) : ceil((use_sz(2) - 1)/2), [1, -floor((use_sz(2) - 1)/2)])';
    newton_iterations = params.newton_iterations;
end

% initialize the projection matrix
rect_position = zeros(num_frames, 4);

time = 0;

% allocate
xxlf_sep = zeros(2*feature_dim, length(dft_sym_ind) + 2 * length(dft_pos_ind), feature_dim, 'single');
multires_pixel_template = zeros(sz(1), sz(2), size(im,3), nScales, 'uint8');

for frame = 1:num_frames
    %load image
    im = imread(s_frames{frame});
    if size(im,3) > 1 && colorImage == false
        im = im(:,:,1);
    end

    tic();
    
    %do not estimate translation and scaling on the first frame, since we 
    %just want to initialize the tracker there
    if frame > 1
        old_pos = inf(size(pos));%inf - �����
        iter = 1;
        
        %translation search
        while iter <= refinement_iterations && any(old_pos ~= pos)
            % Get multi-resolution image
            for scale_ind = 1:nScales%��߶ȵ�ͼ��һ��7���߶ȣ�% get_pixels-extract sample image region
                multires_pixel_template(:,:,:,scale_ind) = ...
                    get_pixels(im, pos, round(sz*currentScaleFactor*scaleFactors(scale_ind)), sz);
            end
            
            xt = bsxfun(@times,get_features(multires_pixel_template,features,global_feat_params),cos_window);
            
            xtf = fft2(xt);
            
            responsef = permute(sum(bsxfun(@times, hf, xtf), 3), [1 2 4 3]);
            
            % if we undersampled features, we want to interpolate the
            % response so it has the same size as the image patch
            if interpolate_response == 2%��̬��ֵ����
                % use dynamic interp size
                interp_sz = floor(size(y) * featureRatio * currentScaleFactor);
            end
            responsef_padded = resizeDFT2(responsef, interp_sz);%���responsef������interp_sz��ά��Ҫ��ʹ�ò�ֵ��ʽʹ������
            
            % response
            response = ifft2(responsef_padded, 'symmetric');%�ԳƸ���Ҷ��任
            
            % find maximum
            if interpolate_response == 3
                error('Invalid parameter value for interpolate_response');
            elseif interpolate_response == 4%ţ�ٷ���ֵ��Ӧ
                [disp_row, disp_col, sind] = resp_newton(response, responsef_padded, newton_iterations, ky, kx, use_sz);
            else
                [row, col, sind] = ind2sub(size(response), find(response == max(response(:)), 1));
                disp_row = mod(row - 1 + floor((interp_sz(1)-1)/2), interp_sz(1)) - floor((interp_sz(1)-1)/2);
                disp_col = mod(col - 1 + floor((interp_sz(2)-1)/2), interp_sz(2)) - floor((interp_sz(2)-1)/2);
            end
            
            % calculate translation
            switch interpolate_response
                case 0
                    translation_vec = round([disp_row, disp_col] * featureRatio * currentScaleFactor * scaleFactors(sind));
                case 1
                    translation_vec = round([disp_row, disp_col] * currentScaleFactor * scaleFactors(sind));
                case 2
                    translation_vec = round([disp_row, disp_col] * scaleFactors(sind));
                case 3
                    translation_vec = round([disp_row, disp_col] * featureRatio * currentScaleFactor * scaleFactors(sind));
                case 4
                    translation_vec = round([disp_row, disp_col] * featureRatio * currentScaleFactor * scaleFactors(sind));
            end
            
            % set the scale
            currentScaleFactor = currentScaleFactor * scaleFactors(sind);
            % adjust to make sure we are not to large or to small
            if currentScaleFactor < min_scale_factor
                currentScaleFactor = min_scale_factor;
            elseif currentScaleFactor > max_scale_factor
                currentScaleFactor = max_scale_factor;
            end
            
            % update position
            old_pos = pos;
            pos = pos + translation_vec;
            
            iter = iter + 1;
        end
        
        % debug visualization of responses
        if debug
            figure(101);
            subplot_cols = ceil(sqrt(nScales));
            subplot_rows = ceil(nScales/subplot_cols);
            for scale_ind = 1:nScales
                subplot(subplot_rows,subplot_cols,scale_ind);
                imagesc(fftshift(response(:,:,scale_ind)));colorbar; axis image;
                title(sprintf('Scale %i,  max(response) = %f', scale_ind, max(max(response(:,:,scale_ind)))));
            end
        end
    end
    
    % extract training sample image region
    pixels = get_pixels(im,pos,round(sz*currentScaleFactor),sz);
    
    % extract features and do windowing
    xl = bsxfun(@times,get_features(pixels,features,global_feat_params),cos_window);
    
    % take the DFT and vectorize each feature dimension
    xlf = fft2(xl);
    xlf_reshaped = reshape(xlf, [support_sz, feature_dim]);
    
    % new rhs sample
    xyf_corr = bsxfun(@times, yf_vec, conj(xlf_reshaped));
    xy_dfs = real(dfs_matrix * double(xyf_corr));
    new_hf_rhs = xy_dfs(:);
    
    xlf_reshaped_sym = xlf_reshaped(dft_sym_ind, :);    % extract the symmetric part of the spectrum x_0
    xlf_reshaped_pos = xlf_reshaped(dft_pos_ind, :);    % extract the positive part of the spectrum x_+
    
    % compute autocorrelation
    xxlf_sym = bsxfun(@times, conj(permute(xlf_reshaped_sym, [2 1])), permute(xlf_reshaped_sym, [3 1 2]));
    xxlf_pos = bsxfun(@times, conj(permute(xlf_reshaped_pos, [2 1])), permute(xlf_reshaped_pos, [3 1 2]));
    xxlf_pos_real = real(xxlf_pos);
    
    % partition the real and imaginary parts
    xxlf_sep(1:2:end, 1:num_sym_coef, :) = real(xxlf_sym);
    xxlf_sep(1:2:end, num_sym_coef+1:2:end, :) = xxlf_pos_real;
    xxlf_sep(2:2:end, num_sym_coef+1:2:end, :) = imag(xxlf_pos);
    xxlf_sep(1:2:end, num_sym_coef+2:2:end, :) = -imag(xxlf_pos);
    xxlf_sep(2:2:end, num_sym_coef+2:2:end, :) = xxlf_pos_real;
    
    if frame == 1
        hf_rhs = new_hf_rhs;
        hf_autocorr = xxlf_sep(:);
        
        % compute the initial filter in the first frame
        hf_init_autocorr = double(sum(xlf_reshaped .* conj(xlf_reshaped), 2));
        switch params.init_strategy
            case 'const_reg'       % exact solution for constant regularization
                hf_init = bsxfun(@rdivide, xyf_corr, hf_init_autocorr + params.reg_window_min^2);
                hf_init = real(dfs_matrix * hf_init);
                hf_vec = hf_init(:);
            case 'indep'           % independent filters for each feature
                A_init = real(dfs_matrix * spdiags(hf_init_autocorr, 0, support_sz, support_sz) * dfs_matrix') + feature_dim * WW_block;
                b_init = reshape(hf_rhs, support_sz, feature_dim);
                hf_init = A_init \ b_init;
                hf_vec = hf_init(:);
        end
        
        if debug == 1
            hf_vec_old = hf_vec;
            hf_difference = zeros(num_frames * num_GS_iter, 1);
        end
    else
        hf_rhs = (1 - learning_rate) * hf_rhs + learning_rate * new_hf_rhs;
        hf_autocorr = (1 - learning_rate) * hf_autocorr + learning_rate * xxlf_sep(:);
    end
    
    % add the autocorrelation to the matrix vectors with the regularization
    L_vec(data_in_L_index) = hf_autocorr(data_L_mask) + WW_L_vec_data;
    
    % update the matrices with the new non-zeros
    AL = setnonzeros(AL, double(L_vec));
    AU_data = setnonzeros(AU_data, double(hf_autocorr(data_U_mask)));
    
    % do Gausss-Seidel��˹-�����µ�������ƽ�
    for iter = 1:num_GS_iter
        hf_vec = AL \ (hf_rhs - AU_data * hf_vec - WW_U * hf_vec);
        
        if debug
            hf_difference((frame - 1)*num_GS_iter + iter) = norm(hf_vec - hf_vec_old);
            hf_vec_old = hf_vec;
        end
    end
    
    % reconstruct the filter
    hf = reshape(single(dfs_matrix' * reshape(hf_vec, [support_sz, feature_dim])), [use_sz, feature_dim]);
    
    % debug visualization
    if debug
        % plot filters
        figure(20)
        subplot_cols = ceil(sqrt(feature_dim));
        subplot_rows = ceil(feature_dim/subplot_cols);
        for disp_layer = 1:feature_dim
            subplot(subplot_rows,subplot_cols,disp_layer);
            imagesc(ifft2(conj(hf(:,:,disp_layer)), 'symmetric')); 
            colorbar;
            axis image;
        end
        
        % plot convergence
        figure(99);plot(hf_difference);axis([1, num_GS_iter * frame, 0, max(hf_difference)]);
        title('Filter optimization convergence');
    end
    
    target_sz = floor(base_target_sz * currentScaleFactor);
    
    %save position and calculate FPS
    rect_position(frame,:) = [pos([2,1]) - floor(target_sz([2,1])/2), target_sz([2,1])];
    
    time = time + toc();
    
    %visualization
    if visualization == 1
        rect_position_vis = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];
        im_to_show = double(im)/255;
        if size(im_to_show,3) == 1
            im_to_show = repmat(im_to_show, [1 1 3]);
        end
        if frame == 1
            fig_handle = figure('Name', 'Tracking');
            imagesc(im_to_show);
            hold on;
            rectangle('Position',rect_position_vis, 'EdgeColor','g', 'LineWidth',2);
            text(10, 10, int2str(frame), 'color', [0 1 1]);
            hold off;
            axis off;axis image;set(gca, 'Units', 'normalized', 'Position', [0 0 1 1])
        else
            resp_sz = round(sz*currentScaleFactor*scaleFactors(scale_ind));
            xs = floor(old_pos(2)) + (1:resp_sz(2)) - floor(resp_sz(2)/2);
            ys = floor(old_pos(1)) + (1:resp_sz(1)) - floor(resp_sz(1)/2);
            sc_ind = floor((nScales - 1)/2) + 1;
            
            figure(fig_handle);
            imagesc(im_to_show);
            hold on;
            resp_handle = imagesc(xs, ys, fftshift(response(:,:,sc_ind))); colormap hsv;
            alpha(resp_handle, 0.5);
            rectangle('Position',rect_position_vis, 'EdgeColor','g', 'LineWidth',2);
            text(10, 10, int2str(frame), 'color', [0 1 1]);
            hold off;
        end
        
        drawnow
         %pause
    end
end

fps = numel(s_frames) / time;

results.type = 'rect';
results.res = rect_position;
results.fps = fps;
