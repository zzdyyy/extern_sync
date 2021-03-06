function [ outImg , param ]  =  shiftable_jointBF(inImg, rangeImg, sigmaS, sigmaR, w, tol)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Filtering operation
%
%   inImg      : MxNxB image to filter (single/double)
%   rangeImg   : MxN image used to for pixel similarity (single/double)
%   outImg     : filtered image of size MxNxB
%   sigmaS     : width of spatial Gaussian
%   sigmaR     : width of range Gaussian
%   [-w, w]^2  : domain of spatial Gaussian
%   tol        : truncation error
%
%   Author: Kunal N. Chaudhury
%   Date:   March 1, 2012
%
%   Modified by: Derek Hoiem
%   Date: May 18, 2012
%   Modifications: Allow inImg to be multiband; allow image for computing
%   pixel similarity to be different than filtered image.
%
%   Reference:  
%
%   [1] K.N. Chaudhury, D. Sage, and M. Unser, "Fast O(1) bilateral  filtering using 
%   trigonometric range kernels," IEEE Transactions on Image Processing, vol. 20, 
%   no. 11, 2011.
%
%   [2] K.N. Chaudhury, "Acceleration of the shiftable O(1) algorithm for bilateral filtering 
%   and non-local means," arXiv:1203.5128v1. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% create spatial filter
filt     = fspecial('gaussian', [w w], sigmaS);

% set range interval and the order of raised cosine
T  =  maxFilter(rangeImg, w);
N  =  ceil( 0.405 * (T / sigmaR)^2 );

gamma    =  1 / (sqrt(N) * sigmaR);
twoN     =  2^N;

% compute truncation
if tol == 0
    M = 0;
else
    if sigmaR > 40
        M = 0;
    elseif sigmaR > 10
        sumCoeffs = 0;
        for k = 0 : round(N/2)
            sumCoeffs = sumCoeffs + nchoosek(N,k)/twoN;
            if sumCoeffs > tol/2
                M = k;
                break;
            end
        end
    else
        M = ceil( 0.5 * ( N - sqrt(4*N*log(2/tol)) ) );
    end
end


% main filter
[m, n, b]  =  size(inImg);
outImg1    =  zeros(m, n, b);
outImg2    =  zeros(m, n, b);
outImg     =  zeros(m, n, b);

warning off; %#ok<WNOFF>

for k = M : N - M
    
    coeff = nchoosek(N,k) / twoN;
    
    temp1  = cos( (2*k - N) * gamma * rangeImg);
    temp2  = sin( (2*k - N) * gamma * rangeImg);
    
    if size(inImg, 3) > 1
      temp1 = repmat(temp1, [1 1 size(inImg, 3)]);
      temp2 = repmat(temp2, [1 1 size(inImg, 3)]);
    end
    
    phi1 =  imfilter(inImg .* temp1, filt);
    phi2 =  imfilter(inImg .* temp2, filt);
    phi3 =  imfilter(temp1, filt);
    phi4 =  imfilter(temp2, filt);
    
    outImg1 = outImg1 + coeff * ( temp1 .* phi1 +  temp2 .* phi2 );
    outImg2 = outImg2 + coeff * ( temp1 .* phi3 +  temp2 .* phi4 );
    
end

idx1 = find( outImg2 < 0.0001);
idx2 = find( outImg2 > 0.0001);

outImg( idx1 ) = inImg( idx1 );
outImg( idx2 ) = outImg1( idx2 ) ./ outImg2 (idx2 );

% save parameters
param.T  = T;
param.N  = N;
param.M  = M;

