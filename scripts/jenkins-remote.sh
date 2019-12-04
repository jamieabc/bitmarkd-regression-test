shared_dir="jenkins"
regression_script="bin/run-regression"
regression_dir="bitmarkd-regression-test"
result_file="${shared_dir}/result.json"
repo="https://github.com/jamieabc/bitmarkd-regression-test.git"

ERROR_CODE=1

# setup env variable
export GOPATH=~/gocode
export PATH=${GOPATH}/bin:$PATH

kill_programs() {
    printf "terminate programs..."
    pkill -9 recorderd
    pkill -9 bitmarkd
    pkill -9 bitcoind
    pkill -9 litecoind
}

printf "\nRemoving previous result...\n"
if [ -f ~/${result_file} ]; then
    rm ~/${result_file}
fi

echo run regression environment setup
eval ~/$regression_script

# check if regression script executed successfully
if [ $? -ne 0 ]; then
    printf "\nregression script execute failed...abort"
    kill_programs
    exit $ERROR_CODE
fi

echo remove existing regression directory
rm -rf ~/${regression_dir}

echo cloning newest regression test cases
git clone --depth 1 "${repo}"

# run test cases
cd ~/${regression_dir}
echo running cucumber...
cucumber --fail-fast -g --format json -o ~/${result_file}

# check cucumber status
if [ $? -ne 0 ]; then
    cucumber_fail="true"
fi

kill_programs

if [ ! -f ~/${result_file} ]; then
    printf "%s not exist, abort...\n" "${result_file}"
    exit $ERROR_CODE
else
    cat ~/${result_file}
fi

# on freebuilder, the shell is zsh, so use single equal sign
if [ "${cucumber_fail}" = "true" ]; then
    exit $ERROR_CODE
fi
