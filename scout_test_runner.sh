#!/bin/bash

TEST_SUITE=$1
NVIM_TEST_COMMAND="nvim --headless -n -c "
GROUP_TEST_ARG="'PlenaryBustedDirectory  "
SINGLE_TEST_ARG="'PlenaryBustedFile  "
TEST_DIR=$(pwd)
TEST_TYPE="group"

test_runner_help() {
    printf "================-Scout Test Runner-================\n\n"
    printf "\tOptions for running tests\n"
    printf "\t -a: Run all tests (Default)\n"
    printf "\t -f: Run functional test suite\n"
    printf "\t -u: Run unit test suite\n"
    printf "\t -s [TEST_PATH]: Run the test located at TEST_PATH\n"
    printf "\t -h: Print this help message"
}

append_to_test_cmd()
{
    OPTION=$1
    NVIM_TEST_COMMAND+=$OPTION
}

append_test_type()
{
    if [ $TEST_TYPE == "group" ]; then
        append_to_test_cmd $GROUP_TEST_ARG
    else
        append_to_test_cmd $SINGLE_TEST_ARG
    fi
}

append_test() {
    TEST=$1
    TEST+="'"
    append_to_test_cmd " "
    append_to_test_cmd $TEST
}

test_all() {
    append_test_type
    append_test "spec"
    run_test
}

test_functional() {
    append_test_type
    append_test "spec/functional"
    run_test
}

test_unit() {
    append_test_type
    append_test "spec/unit"
    run_test
}
test_single() {
    append_test_type
    append_test $1
    run_test
}

run_test(){
    printf "Running test: ${NVIM_TEST_COMMAND}\n"
    bash -c "${NVIM_TEST_COMMAND}"
    exit $?
}

test_runner_main() {
    while getopts ":afus:h" option; do
        case ${option} in
            a)
                test_all
                ;;
            f)
                test_functional
                ;;
            u)
                test_unit
                ;;
            s)
                TEST_TYPE="single"
                test_single $OPTARG
                ;;
            \?)
                printf "Invalid option provided see help below: \n"
                ;&
            h)
                test_runner_help
                ;;
        esac
    done
}

test_runner_main $@ # pass all args
