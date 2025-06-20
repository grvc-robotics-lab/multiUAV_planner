function [N,E, Zone] = ll2utm_fcn(lat, lon)
% 
rec = length(lat);

N = zeros(rec,1);
E = zeros(rec,1);

for i=1:rec
    [N(i),E(i),Zone] = LL2UTM(deg2rad(lat(i)),deg2rad(lon(i)));
end
end


function [N,E,Zone]=LL2UTM(lat,lon)
% ELL2UTM  Converts ellipsoidal coordinates to UTM coordinates.
%   UTM northing and easting coordinates must be in a 6 degree
%   system. Zones begin with zone 1 at longitude 180E to 186E
%   and increase eastward.  Formulae from E.J. Krakiwsky,
%   "Conformal Map Projections in Geodesy", Dept. Surveying
%   Engineering Lecture Notes No. 37, University of New Brunswick,
%   Fredericton, N.B, 1973. Krakwisky meridian arc length (S)
%   replaced with Hermert (1880) expansion. Vectorized.
% Version: 2011-11-13

% Input:   lat - vector of latitudes (rad)
%          lon - vector of longitudes (rad)

% Output:  N   - vector of UTM northings (m)
%          E   - vector of UTM eastings (m)
%          Zone- vector of UTM zones (zeros if lcm specified)
%          lcm - central meridian(s) used in conversion (rad)


a=6378137.0;                %ellipsoid major semi-axis (m)
e2=0.0818^2;                %ellipsoid eccentricity squared

f=1-sqrt(1-e2);
Zone=floor((180/pi*(lon)-180)/6)+1;
Zone=Zone+(Zone<0)*60-(Zone>60)*60;
% Zone=54;
lcm=pi/180*(Zone*6-183);    %optional vector of non-standard central meridians(rad)

ko=0.9996;                  % Scale factor
No=zeros(size(lat));        % False northing (north)
No(lat<0)=1e7;              % False northing (south)
Eo=500000;                  % False easting

lam=lon-lcm;
lam=lam-(lam>=pi)*(2*pi);
  
RN=a./(1-e2*sin(lat).^2).^0.5;
RM=a*(1-e2)./(1-e2*sin(lat).^2).^1.5;
h2=e2*cos(lat).^2/(1-e2);
t=tan(lat);
n=f/(2-f);

%----- Hinks (1927) Bessel series expansion used in DMA definition of UTM
%A0=1 - n + n.^2*5/4 - n.^3*5/4 + n.^4*81/64 - n.^5*81/64;
%A2=3/2*( n - n.^2 + n.^3*7/8 - n.^4*7/8 + n.^5*55/64 );
%A4=15/16*( n.^2 - n.^3 + n.^4*3/4 - n.^5*3/4 );
%A6=35/48*( n.^3 - n.^4 + n.^5*11/16 );
%A8=315/512*( n.^4 - n.^5 );
%S=a*(A0*lat-A2*sin(2*lat)+A4*sin(4*lat)-A6*sin(6*lat)+A8*sin(8*lat));

%----- Helmert (1880) expansion & simplification of Bessel series (faster)
% A0=1+n^2/4+n^4/64;
% A2=3/2*(n-n^3/8);
% A4=15/16*(n^2-n^4/4);
% A6=35/48*n^3;
% A8=315/512*n^4;
% S=a/(1+n)*(A0*lat-A2*sin(2*lat)+A4*sin(4*lat)-A6*sin(6*lat)+A8*sin(8*lat));

%----- Krakiwsky (1973) expansion
A0=1-(e2/4)-(e2^2*3/64)-(e2^3*5/256)-(e2^4*175/16384);
A2=(3/8)*( e2+(e2^2/4)+(e2^3*15/128)-(e2^4*455/4096) );
A4=(15/256)*( e2^2+(e2^3*3/4)-(e2^4*77/128) );
A6=(35/3072)*( e2^3-(e2^4*41/32) );
A8=-(315/131072)*e2^4;
S=a*(A0*lat-A2*sin(2*lat)+A4*sin(4*lat)-A6*sin(6*lat)+A8*sin(8*lat));

E1=lam.*cos(lat);
E2=lam.^3.*cos(lat).^3/6.*(1-t.^2+h2);
E3=lam.^5.*cos(lat).^5/120.*(5-18*t.^2+t.^4+14*h2-58*t.^2.*h2+ ...
   13*h2.^2+4*h2.^3-64*t.^2.*h2.^2-24*t.^2.*h2.^3);
E4=lam.^7.*cos(lat).^7/5040.*(61-479*t.^2+179*t.^4-t.^6);
E=Eo+ko*RN.*(E1+E2+E3+E4);

N1=S./RN;
N2=lam.^2/2.*sin(lat).*cos(lat);
N3=lam.^4/24.*sin(lat).*cos(lat).^3.*(5-t.^2+9*h2+4*h2.^2);
N4=lam.^6/720.*sin(lat).*cos(lat).^5.*(61-58*t.^2+t.^4+ ...
   270*h2-330*t.^2.*h2+445*h2.^2+324*h2.^3-680*t.^2.*h2.^2+ ...
   88*h2.^4-600*t.^2.*h2.^3-192*t.^2.*h2.^4);
N5=lam.^8/40320.*sin(lat).*cos(lat).^7.*(1385-311*t.^2+543*t.^4-t.^6);
N=No+ko*RN.*(N1+N2+N3+N4+N5);
end

