shared_dir="jenkins"
regression_env_script="bin/run-regression"
regression_dir="bitmarkd-regression-test"
result_file="${shared_dir}/result.json"
repo="https://git.bitmark.com:8080/system/bitmarkd-regression-test.git"

ERROR_CODE=1

# setup env variable
export GOPATH=~/gocode
export PATH=${GOPATH}/bin:$PATH

printf "\nRemoving previous result...\n"
if [ -f ~/${result_file} ]; then
    rm ~/${result_file}
fi

echo run regression environment setup
eval ~/$regression_env_script

# check if regression script executed successfully
if [ $? -ne 0 ]; then
    printf "\nregression script execute failed...abort"
    exit $ERROR_CODE
fi

echo remove existing regression directory
rm -rf ~/${regression_dir}

echo cloning newest regression test cases
git clone "${repo}"

# run test cases
cd ~/${regression_dir}
echo running cucumber...
cucumber --fail-fast -g --format json_pretty -o ~/${result_file}

# check cucumber status
if [ $? -ne 0 ]; then
    cucumber_fail="true"
fi

if [ ! -f ~/${result_file} ]; then
    printf "${result_file} not exist, abort..."
    exit $ERROR_CODE
else
    cat ~/${result_file}
fi

# on freebuilder, the shell is zsh, so use single equal sign
if [ "${cucumber_fail}" = "true" ]; then
    exit $ERROR_CODE
fi
