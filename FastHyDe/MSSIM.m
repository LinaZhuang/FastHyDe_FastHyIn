function k = MSSIM(Y, Y_ref, Lines, Columns)
% input size : Bands*observation
 K = [0.01 0.03];
 window = fspecial('gaussian', 11, 1.5);

for i=1:size(Y,1)
     L = max([max(Y(i,:)),max(Y_ref(i,:))]);
    k_tmp(i)  = ssim_index(reshape(Y_ref(i,:),[Lines, Columns]), reshape(Y(i,:),[Lines, Columns]), K, window, L);
end
k=mean(k_tmp);
fprintf('\n The SSIM value is %0.2f', k);