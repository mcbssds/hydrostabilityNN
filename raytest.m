%RAYTEST generate label data without using parallel toolbox
%   IFISS scriptfile: DJS; 26 December 2025
% Copyright (c) 2024 D.J. Silvester
global BATCH bsn FID RA DELTA
setpath
% switch to activate batch mode (off/on 0/1) (see "default.m")
BATCH=1;
tstart = tic; %------- start timing
fprintf('Generating Rayleigh-Benard convection test data set ... ')
%
%----- setup problem data files
system('/bin/cp ./boussinesq_flow/test_problems/bottom_bcX.m ./diffusion/specific_bc.m');
system('/bin/cp ./stokes_flow/test_problems/no_flow.m ./stokes_flow/specific_flow.m');
system('/bin/cp ./diffusion/test_problems/zero_bc.m ./stokes_flow/stream_bc.m');
%
% ---- preprocessing to set up grid and coefficient matrices
testproblem=['B-NS42_grid_batch'];
%---------- write the batch file
      [KID,message]=fopen(testproblem,'w');
      fprintf(KID,'2%%\n1%%\n1%%\n32%%\n2%%\n1%%\n1%%\n');
      fprintf(KID,'%59s\n','%---------- grid data file for Rayleigh-Benard test problem');
      fclose(KID);
%---------- set up matrices
      [FID,message]=fopen(testproblem,'r');
      if strcmp(message,'')~=1, error(['INPUT FILE ERROR: ' message])
      else, disp(['Working in batch mode from data file ',testproblem])
      end
      bsn=1; cavity_boussX
%
%------- run through test data points in parallel
ras = [1510,1530];      %<--- Rayleigh numbers
deltaset = [1e-16,1e-16];  %<--- perturbations to inflow
nra=length(ras); ndelta=length(deltaset);
if nra~=ndelta, error('Oops ... check data setup!'), end

%---------- parallel matlab loop
for test=1:nra
      tt=test;
      fprintf(['\n [%g]'],tt)
      ra=ras(tt); RA=ra;
      fprintf(['\n Rayleigh number %g'],ra)
      delta=deltaset(tt); DELTA = delta;
      fprintf(['\n perturbation magnitude is %g\n'],DELTA)
      testproblem=['B-NS42_test',num2str(tt)];
      batchfile=[testproblem,'_batch.m'];
%      gohome, cd batchfiles
%---------- write the batch file
      [FID,message]=fopen(batchfile,'w');
      fprintf(FID,'%g%%\n7.1%%\n%g%%\n',ra,delta);
      fprintf(FID,'1e16%%\n3%%\n1e-6%%\n0%%\n30%%\n0%%\n0%%\n13%%\n');
      fprintf(FID,'%53s\n','%---------- data file for Rayleigh-Benard test problem');
      fclose(FID);
%---------- execute the batch file and compute the label
      batchprocess(testproblem)
end
etoc = toc(tstart);
fprintf('Bingo!\n')
fprintf('\n  %9.4e seconds\n\n\n',etoc)

%---------- open results file
gohome, cd datafiles
[RID,message]=fopen('ray_labels.txt','w');
fprintf(RID,'%33s\n','%------------ Rayleigh Benard grid32 label results');
for test=1:nra
   testresults=['Bouss_output',num2str(test),'.mat'];
   load(testresults)
   figure(25+test),subplot(121)
   plot(1:length(KE),KE,'ob:'), axis square
   title('kinetic energy')
   subplot(122)
   plot(1:length(VTY),VTY,'ok:'), axis square
   title('mean vorticity')
%---------- check for equilibrium solution
   ke=KE(end); omega=VTY(end);
   if KE(end)<3e-3, label=0; else, label=1; end
%---------- check for incomplete time integration
   if 801==length(time), flag=0; else, flag=1; end
%---------- write the result to the file
   fprintf(RID,'%g,%g,%g,%g,%g,%g\n',Ra,delta,label,ke,omega,flag);
   fprintf('Label results saved for test %g\n',test)
end
fclose(RID);
fprintf('All done\n')

