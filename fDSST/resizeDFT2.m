function resizeddft  = resizeDFT2(inputdft, desiredSize)

imsz = size(inputdft);
minsz = min(imsz, desiredSize);

scaling = prod(desiredSize)/prod(imsz);

resizeddft = complex(zeros(desiredSize, 'single'));%complex - ������������.�� MATLAB ���� ͨ������ʵ�����봴��һ��������� z������ z = a + bi��

mids = ceil(minsz/2);
mide = floor((minsz-1)/2) - 1;

%��������������ֵ���书�ܺ�imresizeһ����������Ҳ�ᵽ�ˣ��������ֵ������λ����zero-padding��
%��Ϊ���е�ֵ����ͬ���������������ݱ�����û�иı䣬����������һ��"ϸ��"��ͼ������м�ֵ���ױ�Ϊ0
%���mesh(inputdft)��mesh(real(desiredSize))����Թ۲쵽��inputdft��ֵҲ���Ľǣ�������ƽ���Ĺ��ɵ����ģ����Խӽ�����λ����Щ������0.
%�������ǽ���imresizeһ������ʱ���ڣ�������ֱ���ڸ��Ͽռ�����������ֵ����������ɵ�resizeddft���Գƣ���������ifft�����ɵľ�����Ȼ�Ǹ�������
%������fDSST.m�ĵ�134�У�����ifftʱʹ��'symmetric'������
resizeddft(1:mids(1), 1:mids(2)) = scaling * inputdft(1:mids(1), 1:mids(2));%ֵ������resizeddft���Ľǣ��м���zero-padding
resizeddft(1:mids(1), end - mide(2):end) = scaling * inputdft(1:mids(1), end - mide(2):end);
resizeddft(end - mide(1):end, 1:mids(2)) = scaling * inputdft(end - mide(1):end, 1:mids(2));
resizeddft(end - mide(1):end, end - mide(2):end) = scaling * inputdft(end - mide(1):end, end - mide(2):end);
end