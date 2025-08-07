function [image_fasthyde, time] = FastHyDe(img_ori, M,  noise_type, iid, k_subspace)

% Input: -------------
%
% img_ori        hyperspectral data set with size (L x C x N),
%                where L, C, and N are the number of rows,
%                columns, and bands, respectively.
%
% M              mask matrix with size (L x C x N),
%                M(i,j,k) = 1, meaning the element is observed.
%                M(i,j,k) = 0, meaning the element is unobserved.
%
% noise_type     {'white','poisson'}
%
% iid            iid = 1 -- Gaussian i.i.d. noise.
%                iid = 0 -- Gaussian non-i.i.d noise.
%                if noise_type is set to 'poisson', then the code does not
%                use the value of iid, which can be set to any value.
%
% k_subspace     signal subspace dimension
%
% Output: --------------
%
% image_fasthyde Denoised hyperspectral data with (L x C x N)
%
% time           Runing time of FastHyDe
%
% ---------------------------- -------------------------------------------
% See more details in papers:
%   [1] L. Zhuang and J. M. Bioucas-Dias, 
%       "Fast hyperspectral image denoising based on low rank and sparse 
%       representations," in 2016 IEEE International Geoscience and Remote
%       Sensing Symposium (IGARSS 2016), 2016.
%
%   [2] L. Zhuang and J. M. Bioucas-Dias, 
%       "Fast hyperspectral image denoising and inpainting based on low rank 
%       and sparse representations," Submitted to IEEE Journal of Selected
%       Topics in Applied Earth Observations and Remote Sensing, 2017.
%       URL: http://www.lx.it.pt/~bioucas/files/submitted_ieee_jstars_2017.pdf
%
%
%% -------------------------------------------------------------------------
%
% Copyright (July, 2017):        
%             Lina Zhuang (lina.zhuang@lx.it.pt)
%             &
%             Jose Bioucas-Dias (bioucas@lx.it.pt)
%            
%
% FastHyIn is distributed under the terms of
% the GNU General Public License 2.0.
%
% Permission to use, copy, modify, and distribute this software for
% any purpose without fee is hereby granted, provided that this entire
% notice is included in all copies of any software which is or includes
% a copy or modification of this software and in all copies of the
% supporting documentation for such software.
% This software is being provided "as is", without any express or
% implied warranty.  In particular, the authors do not make any
% representation or warranty of any kind concerning the merchantability
% of this software or its fitness for any particular purpose."
% ---------------------------------------------------------------------

img_ori = double(img_ori); % Input must be double (not single) to avoid potential NaNs during computation %update on Aug. 2025
[image_fasthyde, time] = FastHyIn_core(img_ori, M,  noise_type, iid, k_subspace);



end
