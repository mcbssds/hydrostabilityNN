%RAYTEST generate label data
%   IFISS scriptfile: DJS; 27 December 2024
% Copyright (c) 2024 D.J. Silvester
global DELTA
diary raytest32.txt
fprintf('Generating Rayleigh-Benard convection test data set ... ')
[RID,message]=fopen('ray_results.txt','w');
fprintf(RID,'%33s\n','%------------ grid32 label results');
test=0;
deltaset=[1e-16];
%[1e-16,1e-12,1e-8,1e-5,1e-4,1e-3,1e-2];  %<--- perturbations to inflow
ndelta=length(deltaset);
for ra=[1510,1530] % 1300:5:1600        %<--- Rayleigh numbers
   for dk = 1:ndelta
      test=test+1;
      fprintf(['\n [%g]'],test)
      fprintf(['\n Rayleigh number %g'],ra)
      delta=deltaset(dk); DELTA = delta;
      fprintf(['\n perturbation magnitude is %g\n'],DELTA)
      testproblem=['B-NS42_test',num2str(test)];
      batchfile=[testproblem,'_batch.m'];
      gohome, cd batchfiles
%---------- write the batch file
      [FID,message]=fopen(batchfile,'w');
      fprintf(FID,'1\n2\n1\n1\n32\n2\n1\n1\n%g\n7.1\n%g\n1e16\n4\n1e-6\n0\n30\n0\n0\n13\n',ra,delta);
      fprintf(FID,'%53s\n','%---------- data file for Rayleigh-Benard test problem');
      fclose(FID);
%---------- execute the batch file and compute the label
      batchmode(testproblem)
      load stabtrBouss_end
      figure(25+test),subplot(121)
      plot(1:length(KE),KE,'ob:'), axis square
      subplot(122)
      plot(1:length(VTY),VTY,'ok:'), axis square
%---------- check for equilibrium solution
      ke=KE(end); omega=VTY(end);
      if KE(end)<3e-3, label=0;
      else, label=1; end
%---------- check for incomplete time integration
      if 801==length(time), flag=0;
      else, flag=1; end
%---------- write the result to the file
      fprintf(RID,'%g,%g,%g,%g,%g,%g\n',ra,delta,label,ke,omega,flag);
   end
end
fclose(RID);
fprintf('\nAll done')
diary off
