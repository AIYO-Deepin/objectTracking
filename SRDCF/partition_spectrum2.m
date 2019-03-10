% Partitions(����) the spectrum(����) of a 2-dimensional signal with dimensions dft_sz into
% the real part, a set of "positive" frequencies and the corresponding
% "negative" frequencies.

%����P4��f���仮������

function [dft_sym_ind, dft_pos_ind, dft_neg_ind] = partition_spectrum2(dft_sz)

% construct the index vector for the half of the spectrum to be saved
spec_dim = ceil((dft_sz+1)/2);%dft_szΪĿ�������height��width
dim_even = mod(dft_sz, 2) == 0;
if dim_even(2) %���dft_sz��widthҲ����use_sz��width���ñ�2����
    % linear indecies of the part of the spectrum that is needed [g_0, g_+]
    dft_ind = [1:spec_dim(1), (dft_sz(1)+1):((spec_dim(2)-1)*dft_sz(1)+spec_dim(1))]';%ð�ŵ��������ȼ�����͵�,dft_int=[1:26,51:1276]'������
    % linear indecies of the part of the spectrum that have a symmetric
    % counterpart g_+
    dft_pos_ind = [2:spec_dim(1)-dim_even(1), dft_sz(1)+1:(spec_dim(2)-1)*dft_sz(1), (spec_dim(2)-1)*dft_sz(1)+(2:spec_dim(1)-dim_even(1))]';
                                                                                  %dft_pos_ind=[2:25,51:1250,1252:1275]'������
else
    dft_ind = [1:spec_dim(1), dft_sz(1)+1:spec_dim(2)*dft_sz(1)]';
    dft_pos_ind = [2:spec_dim(1)-dim_even(1), dft_sz(1)+1:spec_dim(2)*dft_sz(1)]';
end
% linear indices for the part of the spectrum that is real, g_0
dft_sym_ind = setdiff(dft_ind, dft_pos_ind);%setdiff - ������������Ĳ.�� MATLAB ���� ���� A �д��ڵ� B �в����ڵ����ݣ��������ظ��
                                            %dft_sym_ind=[1,26,1251,1276]'������
% construct the indeced for the corresponding negative frequencies
pos_dft_id = zeros(dft_sz);
pos_dft_id(dft_pos_ind) = 1:length(dft_pos_ind);    % give the positive frequencies id:s corresponding to the order
neg_dft_loc = reflect_spectrum2(pos_dft_id);         % reflect to get the locations of corresponding negative indices
[dft_neg_ind_unsorted, ~, corresponding_dft_pos_id] = find(neg_dft_loc(:)); % find the indices and corresponding positive id:s%find - ���ҷ���Ԫ�ص�������ֵdft_neg_ind_unsortedΪ����Ԫ���У�corresponding_dft_pos_idΪ����Ԫ��ֵ
[~, dft_neg_ind_order] = sort(corresponding_dft_pos_id);    % sort the id:s
dft_neg_ind = dft_neg_ind_unsorted(dft_neg_ind_order);      % get the corresopnding negative indices,dft_neg_ind=[27:50,1277:2500]'������