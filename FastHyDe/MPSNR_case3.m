function k = MPSNR(Y, Y_ref)
% input size : Bands*observation

[B,n] = size(Y);
Err = Y-Y_ref;
for i=1:size(Y,1)
 
maxy = max(Y_ref(i,:));
mse = norm(Err(i,:),'fro')^2/n;
      k_tmp(i) = 10*log10(maxy^2/mse);
end
k=mean(k_tmp);
fprintf('\n The Peak-SNR value is %0.2f', k);