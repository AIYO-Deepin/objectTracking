% ��άgauss����,

function val = gaussC(x, y, sigma, a, center)
    xc = center(1);
    yc = center(2);
%     sigma_x = std(xc,0,2).^2;
%     sigma_y = std(yc,0,1).^2;
    exponent = ((x-xc).^2 + (y-yc).^2)./(2*sigma^2);%�������sigma���Ƕ���x��yȡֵһ��,�������ڶ�ά��˹ģ����ƽ����ͶӰ����һ��Բ��,��˼���ھ���Ŀ������(xc,yc)һ���������
                                                    %��ȡ�õ�Ȩ����һ����.��ȡ��һ����ֵ,��ôͶӰΪһ����Բ��,����Ŀ������һ��������¾ͻ�õ���һ����Ȩ��.
%     exponent = ((x-xc).^2)./(2*sigma_x^2) + ((y-yc).^2)./(2*sigma_y^2);
    val = a * (exp(-exponent)); 