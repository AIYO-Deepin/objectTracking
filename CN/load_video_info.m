function [img_files, pos, target_sz, ground_truth, video_path] = load_video_info(base_path, video)
%LOAD_VIDEO_INFO
%   Loads all the relevant information for the video in the given path:
%   the list of image files (cell array of strings), initial position
%   (1x2), target size (1x2), the ground truth information for precision
%   calculations (Nx2, for N frames), and the path where the images are
%   located. The ordering of coordinates and sizes is always [y, x].
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/
%ʹ��KCF��load_video_info.m�滻��ԭ����load_video_info.m������KCF��������á�
%ͬʱΪ����ӦCN���룬�Բ��������޸ġ�

	%see if there's a suffix(��׺), specifying(ȷ��) one of multiple targets, for
	%example the dot and number in 'Jogging.1' or 'Jogging.2'.
    %������"Jogging"����һ���ļ��а���������Ƶ��Ϣ�����������ʹ�����ݼ�ʱ�����ֶ��ֿ�
	if numel(video) >= 2 && video(end-1) == '.' && ~isnan(str2double(video(end)))
		suffix = video(end-1:end);  %remember the suffix
		video = video(1:end-2);  %remove it from the video name
	else
		suffix = '';
	end

	%full path to the video's files
	if base_path(end) ~= '/' && base_path(end) ~= '\'
		base_path(end+1) = '/';
	end
	video_path = [base_path video '/'];

	%try to load ground truth from text file (Benchmark's format)
	filename = [video_path 'groundtruth_rect' suffix '.txt'];
	f = fopen(filename);
	assert(f ~= -1, ['No initial position or ground truth to load ("' filename '").'])
    
    %textscan - ���Ѵ򿪵��ı��ļ��е����ݶ�ȡ��Ԫ������ C
    %�� textscan δ�ܶ�ȡ��ת������ʱ����Ϊ��ָ��Ϊ�� 'ReturnOnError' �� true/false ��ɵĶ��ŷָ����顣����� true���� textscan ��ֹ��
    %���������󣬷������ж�ȡ���ֶΡ������ false���� textscan ��ֹ���������󣬲��������Ԫ�����顣
    
    %the format is [x, y, width, height]
	try
		ground_truth = textscan(f, '%f,%f,%f,%f', 'ReturnOnError',false);  
	catch  % try different format (no commas)
		frewind(f);      %frewind - ���ļ�λ��ָʾ�����������ļ��Ŀ�ͷ
		ground_truth = textscan(f, '%f %f %f %f');  
	end
	ground_truth = cat(2, ground_truth{:});%cat - ��ָ��ά�ȴ�������,cat(dim,A,B),dim=1��[A;B],dim=2��[A,B]
	fclose(f);
	
	%set initial position and size
	target_sz = [ground_truth(1,4), ground_truth(1,3)];
%     pos = [ground_truth(1,2), ground_truth(1,1)] +floor(target_sz/2);  %KCF�������
	pos = [ground_truth(1,2), ground_truth(1,1)] ;%����CN�õ�pos�����������꣬�������Ͻ�����
	
	if size(ground_truth,1) == 1%����ground_truth�ڵ�һ��ά�ȵĳ��ȣ�������ground_truth������
		%we have ground truth for the first frame only (initial position)
		ground_truth = [];
	else
		%store positions instead of boxes
%         ground_truth = ground_truth(:,[2,1]) + ground_truth(:,[4,3]) /2; %KCF�������
		ground_truth = [ground_truth(:,[2,1]) + (ground_truth(:,[4,3]) - 1) / 2 , ground_truth(:,[4,3])];%�����ȥ1������������ָ��Ӱ�춼����
	end
	
	
	%from now on, work in the subfolder where all the images are
	video_path = [video_path 'img/'];
	
	%for these sequences, we must limit ourselves to a range of frames.
	%for all others, we just load all png/jpg files in the folder.
    %���ڼ����������Ƶ����ֻȡ�����ݼ��е�һ����֡����������Ƶ��ȡ����֡
	frames = {'David', 300, 770;
			  'Football1', 1, 74;
			  'Freeman3', 1, 460;
			  'Freeman4', 1, 283};
	
	idx = find(strcmpi(video, frames(:,1))); %strcmpi - �Ƚ��ַ����������ִ�Сд��,���������ͬ������������ 1 (true)�����򷵻ؿ�����
	
	if isempty(idx) 
		%general case, just list all images
		img_files = dir([video_path '*.png']);%dir�����ʽΪstruct�ṹ������
		if isempty(img_files)
			img_files = dir([video_path '*.jpg']);
			assert(~isempty(img_files), 'No image files to load.')
		end
		img_files = sort({img_files.name});%sort - �����������Ԫ�ؽ�����������ĸ�ʽΪcellԪ������
	else
		%list specified frames. try png first, then jpg.
		if exist(sprintf('%s%04i.png', video_path, frames{idx,2}), 'file')
			img_files = num2str((frames{idx,2} : frames{idx,3})', '%04i.png');%�����ʽΪchar�ַ���
			
		elseif exist(sprintf('%s%04i.jpg', video_path, frames{idx,2}), 'file')
			img_files = num2str((frames{idx,2} : frames{idx,3})', '%04i.jpg');
			
		else
			error('No image files to load.')
		end
		
		img_files = cellstr(img_files);%��char����ת����cellԪ������
	end
	
end
