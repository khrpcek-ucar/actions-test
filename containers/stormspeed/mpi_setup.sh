git config --global user.email "example_user@example.com"
git config --global user.name "example_user"
cd /stormspeed/cime/scripts
./create_newcase --case /tmp/ci_test --machine cirrus --compset FADIAB --res ne30_ne30_mg17 --compiler intel  --run-unsupported

echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
echo "UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config

cd /tmp/ci_test
./xmlchange NTASKS=20
./xmlchange CAM_TARGET='theta0-1'
./xmlchange STOP_OPTION=ndays,STOP_N=1,RESUBMIT=0
./xmlchange DOUT_S='FALSE'
./xmlchange  MPI_RUN_COMMAND='mpiexec -n 20 --hostfile /etc/mpi/hostfile -np "2" -bind-to none -map-by slot -x LD_LIBRARY_PATH -x PATH -mca pml ob1 --allow-run-as-root'
#if [ "${{ matrix.runner }}" == "gha-runner-gpu-stormspeed" ]; then
#   ./xmlchange GPU_TYPE=a10
#   ./xmlchange KOKKOS_GPU_OFFLOAD=TRUE
#   ./xmlchange OVERSUBSCRIBE_GPU=FALSE
#fi
./case.setup
#########
# Build #
#########
./case.build


########################
# Output daily average #
########################
cd /tmp/ci_test
cat <<EOF > user_nl_cam
se_statefreq = 488,
mfilt=1,
ndens=1,
nhtfrq=-24,
inithist='ENDOFRUN'
/
EOF
cat <<EOF > user_nl_cice
empty_htapes = .true.,
fincl1 = '',
/
EOF
################
# Run the test #
################
eval `/opt/spack/bin/spack load --sh gcc`
eval `/opt/spack/bin/spack load --sh prrte`
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PIO/lib:$NETCDF_FORTRAN_PATH/lib:$NETCDF_C_PATH/lib:$LAPACK/lib:$LAPACK/lib64:$PNETCDF/lib
#if [ "${{ matrix.runner }}" == "gha-runner-gpu-stormspeed" ]; then
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CUDA_ROOT/lib64:$CUDA_ROOT/lib64/stubs
#else
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$MKLROOT/lib
./case.submit --no-batch 2>&1 | tee "$TMP_OUTPUT"
sleep 120
