shared_dir="jenkins"
regression_env_script="bin/run-regression"
regression_dir="bitmarkd-regression-test"
result_file="${shared_dir}/result.json"
repo="https://git.bitmark.com:8080/system/bitmarkd-regression-test.git"
conf="conf/cli.conf"

# setup env variable
export PATH=~/gocode/bin:$PATH

echo removing previous result
rm ~/${result_file}

echo run regression environment setup
eval ~/$regression_env_script

echo remove existing regression directory
rm -rf ~/${regression_dir}

echo cloning newest regression test cases
git clone "${repo}"

# copy conf file
cp ~/${conf} ~/${regression_dir}/

# run test cases
cd ~/${regression_dir}
echo running cucumber...
cucumber --format json -o ~/${result_file}

# check cucumber status
if [ $? -ne 0 ]; then
    cucumber_fail=true
fi

cat ~/${result_file}

if [ "${cucumber_fail}" = true ]; then
    exit -1
fi