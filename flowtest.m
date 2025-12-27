%FLOWTEST generate label data without using parallel toolbox
%   IFISS scriptfile: 26 December 2025
% Copyright (c) 2025 D.J. Silvester
global BATCH DELTA FID RE
setpath
BATCH=1;
tstart = tic; %------- start timing
fprintf('Generating channel flow problem test data set ... \n')

%----- setup problem data files
system('/bin/cp ./stokes_flow/test_problems/symstep_flowX.m ./stokes_flow/specific_flow.m');
system('/bin/cp ./stokes_flow/test_problems/symstep_bc.m ./stokes_flow/stream_bc.m');

% ---- preprocessing to set up grid and coefficient matrices
testproblem=['T-NS_batch'];
%---------- write the batch file
      [KID,message]=fopen(testproblem,'w');
      fprintf(KID,'16%%\n5%%\n1%%\n4%%\n');
      fprintf(KID,'%48s\n','%---------- grid data file for flow test problem');
      fclose(KID);

%---------- set up matrices
      [FID,message]=fopen(testproblem,'r');
      if strcmp(message,'')~=1, error(['INPUT FILE ERROR: ' message])
      else, disp(['Working in batch mode from data file ',testproblem])
      end
      symstep_stokes

%------- run through test data points in parallel
nu=[0.0047,0.0045];  %<--- viscosity parameters
reynold = 1./nu; %<--- Reynold numbers
nre=length(reynold);
deltaset = [1e-16,1e-16];
%<--- perturbations to inflow
npr=length(deltaset);
if nre~=npr, error('Oops ... check data setup!'), end

%---------- parallel matlab loop
for test=1:nre
      tt=test;
      fprintf(['\n [%g]'],tt)
      re=reynold(tt); RE=re;
      fprintf(['\n Reynold number %g'],re)
      pr=deltaset(tt);
      fprintf(['\n perturbation is %g\n'],pr)
      testproblem=['T-NS_test',num2str(tt)];
      batchfile=[testproblem,'_batch.m'];
%      gohome, cd batchfiles
%---------- write the batch file
      [FID,message]=fopen(batchfile,'w');
      fprintf(FID,'%g%%\n%g%%\n',re,pr);
      fprintf(FID,'1e15%%\n6%%\n3e-6%%\n2%%\n2500%%\n0%%\n');
      fprintf(FID,'%43s\n','%---------- data file for flow test problem');
      fclose(FID);
%---------- execute the batch file and compute the label
      batchprocess(testproblem)
end
etoc = toc(tstart);
fprintf('Bingo!\n')
fprintf('\n  %9.4e seconds\n\n\n',etoc)

gohome, cd datafiles
load step_stokes_nobc.mat
%---------- open results file
[RID,message]=fopen('flow_labels.txt','w');
fprintf(RID,'%43s\n','%------------ channel flow grid5 label data');
for test=1:nre
   testresults=['symmetric_flow_output',num2str(test),'.mat'];
   load(testresults)
   figure(100+test),subplot(121)
   plot([10:1200],vty(10:1200),'.-r'), axis square
   xlabel('step'), title('mean vorticity')
   subplot(122)
   plot([1000:1200],vty(1000:1200),'.-r'), axis square
   xlabel('step'), title('zoom')
%---------- check for bifurcated solution
   vv=[-By,Bx]*U; nvv=length(vv); w=G(1:nvv,1:nvv)\vv;
   [label,it,ib] = symstep_bdryvorticity(domain,qmethod,xy,bound,w,10+test,'or-');
%---------- check for incomplete time integration
      if 1200==length(time), flag=0;
      else, flag=1; end
%---------- write the result to the file
      fprintf(RID,'%g,%g,%g,%g,%g,%g\n',Re,delta,label,it,ib,flag);
end
fclose(RID);
fprintf('All done\n')

