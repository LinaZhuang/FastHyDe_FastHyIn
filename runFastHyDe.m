%% Name: runFastHyDe
%
%  Generate the denoising results of FastHyDe reported in Tabs. 1-4
%  of paper:
%
% L. Zhuang and J. Bioucas-Dias, "Fast hyperspectral image denoising and 
% inpainting based on low-rank and sparse representations", Submitted to 
% IEEE Journal of Selected Topics in Applied Earth Observations and Remote 
% Sensing, 2017.
%
%  URL: http://www.lx.it.pt/~bioucas/files/submitted_ieee_jstars_2017.pdf
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPORTANT NOTE:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%      This script uses the package BM3D  (v2 (30 January 2014))
%      to implement the denoising algorithm BM3D introduced in
%
%      K. Dabov, A. Foi, V. Katkovnik, and K. Egiazarian, "Image denoising by
%      sparse 3D transform-domain collaborative filtering," IEEE Trans.
%      Image Process., vol. 16, no. 8, pp. 2080-2095, August 2007.
%
%      The BM3D package  is available at the
%      BM3D web page:  http://www.cs.tut.fi/~foi/GCF-BM3D
%
%      Download this package and install it is the folder /BM3D
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Lina Zhuang (lina.zhuang@lx.it.pt)
%         &
%         Jose M. Bioucas-Dias (bioucas@lx.it.pt)
%         July, 2017
%%


clear;clc;close all;
addpath(' BM3D');
% Q: How to run the different set of parameters?
% A: testdataset          1 - Pavia image;
%                         2 - DC image.
%    which_case           'case1' - additive Gaussian i.i.d. noise; 
%                         'case2' - additive Gaussian non-i.i.d. noise; 
%                         'case3' - Poissonian noise.
%    i_img                If additive Gaussian i.i.d. noise is added, 
%                         you may choose specific noise level.  
%                         i_img \in {1,2,3,4,5} decides different noise
%                         standard deviation values will be used, which
%                         are 0.10, 0.08, 0.06, 0.04, and 0.02, respectively.

%%
% USAGE EXAMPLES:
testdataset = 1;        
which_case = 'case1';
i_img=5;               
p_subspace = 10; %Dimension of the subspace
% %--------------------------
% testdataset = 1;
% which_case = 'case2';
% p_subspace = 10;
% %--------------------------
% testdataset = 2;
% which_case = 'case3';
% p_subspace = 10;
% %--------------------------




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% Simulate noisy image with different noise level  %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%  load clean image
%How to generate clean image? See more details in datasets\gen_data_sets.m
if testdataset==1  % testdataset=Pavia
    scene_name = 'pavia';
    load datasets\img_clean_pavia_withoutNormalization.mat;
    
else % testdataset= dc
    scene_name = 'WashingtonDC';
    load datasets\img_clean_dc_withoutNormalization.mat;
    
end
fprintf(['\n','\n','Test dataset: ',scene_name,'  ',which_case,'\n']);

 [row, column, band] = size(img_clean);
N=row*column;


    switch which_case
        case {'case1','case2'} 
    %Before adding noise, the gray values of each HSI band are normalized to [0,1].
    for i =1: band
        y = img_clean(:, :, i) ;
        max_y = max(y(:));
        min_y = min(y(:));
        y =  (y - min_y)./ (max_y - min_y);
        img_clean(:, :, i) = y;
    end
        otherwise %without normalization
            %do nothing
    end






%Add noise
switch which_case
    case 'case1'
        %--------------------- Case 1 --------------------------------------
        
        % zero-mean Gaussian noise is added to all the bands of the Washington DC Mall
        % and Pavia city center data.
        % The noise standard deviation values are 0.02, 0.04, 0.06, 0.08, and 0.10, respectively.
        noise_type='additive';
        iid = 1; %It is true that noise is i.i.d.
        switch i_img
            case 1
                sigma = 0.1;randn('seed',0);
            case 2
                sigma = 0.08;randn('seed',i_img*N);
            case 3
                sigma = 0.06;randn('seed',i_img*N);
            case 4
                sigma = 0.04;randn('seed',i_img*N);
            case 5
                sigma = 0.02;randn('seed',i_img*N);
        end
        
        %generate noisy image
        noise = sigma.*randn(size(img_clean));
        img_noisy=img_clean+noise;
        
    case 'case2'
        %---------------------  Case 2 ---------------------
        
        % Different variance zero-mean Gaussian noise is added to
        % each band of the two HSI datasets.
        % The std values are randomly selected from 0 to 0.1.
        noise_type='additive';
        iid = 0; %noise is not i.i.d.
        rand('seed',0);
        sigma = rand(1,band)*0.1;
        randn('seed',0);
        noise= randn(size(img_clean));
        for cb=1:band
            noise(:,:,cb) = sigma(cb)*noise(:,:,cb);
            
        end
        img_noisy=img_clean+noise;
        
        
        
        
    case 'case3'
        %  ---------------------  Case 3: Poisson Noise ---------------------
        noise_type='poisson';
         iid = NaN; % noise_type is set to 'poisson', 
        img_wN = img_clean;
        
        snr_db = 15;
        snr_set = exp(snr_db*log(10)/10);
        
        for i=1:band
            img_wNtmp=reshape(img_wN(:,:,i),[1,N]);
            img_wNtmp = max(img_wNtmp,0);
            factor = snr_set/( sum(img_wNtmp.^2)/sum(img_wNtmp) );
            img_wN_scale(i,1:N) = factor*img_wNtmp;
            % Generates Poisson random samples
            img_wN_noisy(i,1:N) = poissrnd(factor*img_wNtmp);
        end
        
        img_noisy = reshape(img_wN_noisy', [row, column band]);
        img_clean = reshape(img_wN_scale', [row, column band]);
        
        
end


Y_clean = reshape(img_clean, N, band)';
Y_noisy = reshape(img_noisy, N, band)';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%           FastHyDe        %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


 
addpath('FastHyDe');
[img_fasthyde, time_fasthyde] = FastHyDe(img_noisy,  noise_type, iid, p_subspace);
Y_fasthyde  = reshape(img_fasthyde, [],band)';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%  show original and reconstructed data   %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(100);
set(gcf,'outerposition',get(0,'screensize'))
i=1;
time_fig=[];
title_fig={};
figdata=[];
figdata(1:band,1:N,i)=Y_clean;          i=i+1;    time_fig=[time_fig,0];                 title_fig={title_fig{:},'Clean '};
figdata(:,:,i)=Y_noisy;                  i=i+1;    time_fig=[time_fig,0];                 title_fig={title_fig{:},'Noisy band'};
figdata(:,:,i)=Y_fasthyde;     i=i+1;    time_fig=[time_fig,round(time_fasthyde)];         title_fig={title_fig{:},'FastHyDe'};


band_show=50;
figdata_sort=sort(figdata(:));
cmin=figdata_sort(fix(size(figdata_sort,1)*0.2));
cmax=figdata_sort(fix(size(figdata_sort,1)*0.99));
for i=1:size(figdata,3)
    
    subplot(1,size(figdata,3),i);
    subimg = reshape(figdata(band_show,:,i),[row,column]);
    imshow(subimg,[cmin, cmax]);
    
    switch noise_type
        case 'poisson'
            psnr_fig(i) = MPSNR_case3( figdata(:,:,i), Y_clean);
            info_noise = ['Case 3: Poisson noise'];
        case 'additive'
            psnr_fig(i) = MPSNR( figdata(:,:,i), Y_clean);
            if iid
            info_noise = ['Case 1: Additive Gaussion  i.i.d. noise: N(0,',num2str(sigma),'^2)'];
            else
                info_noise = ['Case 2: Additive Gaussion  non-i.i.d. noise'];
            end
           
       
    end
    
    mssim_fig(i) = MSSIM(figdata(:,:,i), Y_clean, row, column);
    
    if i==1
        title({['Runing ', scene_name,' data'],[title_fig{i},num2str(band_show), 'th band']});
    else
        if i==2
            strtmp1=['MPSNR:  ',num2str(fix(psnr_fig(i))),' dB'];
            strtmp2=['MSSIM:  ', num2str(mssim_fig(i))];
            title({title_fig{i},info_noise,strtmp1,strtmp2});
        else
            strtmp1=['MPSNR:  ',num2str(fix(psnr_fig(i))),' dB'];
            strtmp2=['MSSIM:  ', num2str(mssim_fig(i))];
            strtmp3=['Time:  ',num2str(time_fig(i)),' sec'];
            title({title_fig{i},strtmp1,strtmp2,strtmp3});
        end
    end
    
end




