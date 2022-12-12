%% Name: runFastHyIn
%
%  Generate the inpainting results of FastHyIn reported in Tabs. 5 and 6.
%  of paper:
%
% L. Zhuang and J. Bioucas-Dias,"Fast hyperspectral image denoising and 
% inpainting based on low-rank and sparse representations", Submitted to 
% IEEE Journal of Selected Topics in Applied Earth Observations and 
% Remote Sensing, 2017.
%
%  URL: http://www.lx.it.pt/~bioucas/files/submitted_ieee_jstars_2017.pdf
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPORTANT NOTE:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%      This script uses the package bandM3D  (v2 (30 January 2014))
%      to implement the denoising algorithm bandM3D introduced in
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
% Q: How to run the different set of parameters?
% A: testdataset          1 --  Pavia image
%                         2 -- dc image
%    which_case           'case1' -- additive Gaussian i.i.d. noise 
%                         'case2' -- additive  Gaussian non-i.i.d. noise
%                         'case3' --  Poissionian noise
% USAGE EXAMPLES:

testdataset = 1;      
which_case = 'case1';
p_subspace = 10;
% %--------------------------
% testdataset = 2;
% which_case = 'case2';
% p_subspace = 10;
% %--------------------------
% testdataset = 1;
% which_case = 'case3';
% p_subspace = 10;
% %--------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulate noisy image with different noise levels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%  load clean image
%  Regarding the generation of the  clean image, see datasets\gen_data_sets.m
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
        
        % zero-mean gaussian noise is added to all the bands of the Washington DC Mall
        % and Pavia city center data
        
        noise_type='additive';
        iid = 1;
        i_img=1;
        sigma = 0.1;randn('seed',0);
        
        %generate noisy image
        noise = sigma.*randn(size(img_clean));
        img_noisy=img_clean+noise;
        
    case 'case2'
        %---------------------  Case 2 ---------------------
        
        % Different variance zero-mean Gaussian noise is added to
        % each band of the two HSI datasets
        % The std values are randomly selected from 0 to 0.1.
         noise_type='additive';
         iid = 0;
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
          iid = NaN; % noise_type is set to 'poisson'
        img_wN = img_clean;
        
        snr_db = 15;
        snr_set = exp(snr_db*log(10)/10);
        
        for i=1:band
            img_wNtmp=reshape(img_wN(:,:,i),[1,N]);
            img_wNtmp = max(img_wNtmp,0);
            factor = snr_set/( sum(img_wNtmp.^2)/sum(img_wNtmp) );
            img_wN_scale(i,1:N) = factor*img_wNtmp;
            % Generates random samples from a Poisson distribution
            img_wN_noisy(i,1:N) = poissrnd(factor*img_wNtmp);
        end
        
        img_noisy = reshape(img_wN_noisy', [row, column band]);
        img_clean = reshape(img_wN_scale', [row, column band]);
        
        
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulate stripes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%dead lines are simulated for the four bands from band 60 to band 63.
M=ones(size(img_noisy));
img_noisy_nan=img_noisy;
bands_strp=60:63;
for ib =  bands_strp
    
    if ib == 60
        
        
        loc_strp = ceil(rand(1,20)*column);
        switch which_case
            case 'case1'
                
                loc_strp = [loc_strp, 180:190];%loc_strp = [loc_strp, 200:210];
                loc_strp = [loc_strp, 120:140]; %simulate a hole
            case 'case2'
                loc_strp = [loc_strp, 20:40];
                loc_strp = [loc_strp, 160:175]; %simulate a hole
            case 'case3'
                loc_strp = [loc_strp, 70:90];
                loc_strp = [loc_strp, 150:160]; %simulate a hole
        end
    end
    %         img_noisy_nan(:,loc_strp,ib)=zeros(row,size(loc_strp,2))*NaN;
    img_noisy(:,loc_strp,ib)=zeros(row,size(loc_strp,2));
    M(:,loc_strp,ib)=zeros(row,size(loc_strp,2));
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%           FastHyIn        %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath('FastHyDe');
[img_fasthyde, time_fasthyde] = FastHyIn(img_noisy, M, noise_type, iid, p_subspace);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%  show original and reconstructed data   %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
Y_ori = reshape(img_noisy, [],band)';
Y_clean  = reshape(img_clean, [],band)';
Y_fasthyde  = reshape(img_fasthyde, [],band)';
 

figure(100);
set(gcf,'outerposition',get(0,'screensize'))
i=1;
time_fig=[];
title_fig={};
figdata=[];
figdata(1:band,1:N,i)=reshape(img_clean, N, band)';         i=i+1;    time_fig=[time_fig,0];                 title_fig={title_fig{:},'Clean '};
figdata(:,:,i)= reshape(img_noisy, N, band)';               i=i+1;    time_fig=[time_fig,0];                 title_fig={title_fig{:},'Noisy band'};
figdata(:,:,i)= reshape(img_fasthyde, N, band)';       i=i+1;    time_fig=[time_fig,round(time_fasthyde)];         title_fig={title_fig{:},'FastHyIn'};


band_show=60;
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



