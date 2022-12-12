function k = MPSNR(Y, Y_ref)
% input size : Bands*observation

[B,n] = size(Y);
Err = Y-Y_ref;
for i=1:size(Y,1)
%     k_tmp(i)  = psnr(Y_ref(i,:),Y(i,:));

      k_tmp(i) = 10*log10(n/norm(Err(i,:),'fro')^2);
end
k=mean(k_tmp);
fprintf('\n The Peak-SNR value is %0.2f', k);