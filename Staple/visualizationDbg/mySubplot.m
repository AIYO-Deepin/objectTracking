function mySubplot(figureHandle, subplotWidth, subplotHeight, subplotPos, img, imgTitle, newMap)
% MYSUBPLOT creates a matrix of subplots, each with a custom colormap    
    changeMap = sprintf('colormap %s', newMap);%sprintf - �����ݸ�ʽ��Ϊ�ַ���
    figure(figureHandle)%��figureHandle��figure�ϻ�ͼ	
    subplot(subplotWidth, subplotHeight, subplotPos)%�������
	imagesc(img) %imagesc - ��ʾʹ�þ������ӳ�����ɫ��ͼ��
    eval(changeMap);%eval - ִ���ı��е� MATLAB ���ʽ,�����Ǹ�ͼ����ɫ
    freezeColors %������ɫɫ�꣬��ֹ��ͬһfigure�ϻ���ͼʱ����ɫɫ��ı���������Ķ��ı��ˡ�
	pbaspect([size(img,2),size(img,1),1]);%pbaspect - ����ÿ�������Գ���,���õ�ǰ��������ͼ���ݺ��
	title(imgTitle)
    axis off;
end