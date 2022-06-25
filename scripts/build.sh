#!/usr/bin/env bash
set -eu

# declare -a -r platforms=('OS64' 'MAC' 'MAC_ARM64' 'SIMULATOR64' 'SIMULATORARM64')
declare -a -r platforms=('OS64' 'MAC' 'MAC_ARM64' 'SIMULATOR64')

declare -a working_dir='/tmp/build-lib'
declare -a output="$working_dir/result"

if [[ -e $working_dir ]]; then rm -rf $working_dir; fi
mkdir -p $output

declare -a libz_source="$working_dir/source/zlib"
declare -a libz_include="$working_dir/source/zlib-include"
declare -a lvdb_source="$working_dir/source/leveldb-mcpe"
declare -a lvdb_include="$working_dir/source/leveldb-mcpe/include"

# ########## ########## ########## ########## ########## ########## ########## #

# $1: platform
function stop() {
    open .
    echo ''
    if [[ $platform == 'OS64' ]]; then
        read -p "Waiting: change version, add a team, delete unnecessary targets"
    else
        read -p "Waiting: change version"
    fi
    echo 'continue...'
    echo ''
}

# $1: platform
# $2: prefix
function mv_built_lib() {
    declare -a dst_dir=$output/$2-$1
    if [[ -e $dst_dir ]]; then rm -rf $dst_dir; fi
    case $1 in
    'OS64')
        mv Release-iphoneos $dst_dir
        ;;
    'MAC' | 'MAC_ARM64')
        mv Release $dst_dir
        ;;
    'SIMULATOR64' | 'SIMULATORARM64')
        mv Release-iphonesimulator $dst_dir
        ;;
    *)
        cd .. && mv build $dst_dir
        ;;
    esac
}

# ########## ########## ########## ########## ########## ########## ########## #

function prepare() {
    if [[ ! -e zlib-diff.patch ]] || [[ ! -e lvdb-diff.patch ]]; then
        echo 'Error: diff patch file not found!'
        exit 1
    fi
    cp ./*.patch $working_dir
    cd $working_dir
    mkdir source && cd source

    git clone https://github.com/madler/zlib.git                # tag: v1.2.12, commit 21767c654d31d2dccdde4330529775c6c5fd5389
    git -C zlib apply $working_dir/zlib-diff.patch
    mkdir zlib-include
    cp zlib/*.h zlib-include

    git clone https://github.com/Amulet-Team/leveldb-mcpe.git   # tag: 0.7.2, commit 8a0ef86d187fe4846c797ef0a4aa68b0f9658dc3
    git -C leveldb-mcpe apply $working_dir/lvdb-diff.patch
    mv leveldb-mcpe/CMakeLists.txt leveldb-mcpe/CMakeLists.txt.bak

    git clone https://github.com/leetal/ios-cmake.git
    ln -s $working_dir/source/ios-cmake/ios.toolchain.cmake $working_dir/ios.toolchain.cmake
}

function build_libz() {
    # MAC: Release
    for platform in ${platforms[*]}; do
        echo '========== ========== ========== ========== ========== =========='
        echo "Building library for libz on platform $platform ..."

        if [[ -e $libz_source/build ]]; then rm -rf $libz_source/build; fi
        mkdir $libz_source/build && cd $libz_source/build

        cmake .. -G Xcode -DCMAKE_TOOLCHAIN_FILE=$working_dir/ios.toolchain.cmake -DPLATFORM=$platform
        stop
        cmake --build . --config Release
        mv_built_lib $platform 'libz'
        echo ''
    done
    if [[ -e $libz_source/build ]]; then rm -rf $libz_source/build; fi
}

function build_libleveldb() {
    for platform in ${platforms[*]}; do
        echo '========== ========== ========== ========== ========== =========='
        echo "Building library for libleveldb on platform $platform ..."

        if [[ -e $lvdb_source/build ]]; then rm -rf $lvdb_source/build; fi
        mkdir $lvdb_source/build && cd $lvdb_source/build

        cp ../CMakeLists.txt.bak ../CMakeLists.txt
        sed -i -e "s#{{libz_include}}#$libz_include#" $lvdb_source/CMakeLists.txt
        sed -i -e "s#{{libz_static}}#$output/libz-$platform/libz.a#" $lvdb_source/CMakeLists.txt

        cmake .. -G Xcode -DCMAKE_TOOLCHAIN_FILE=$working_dir/ios.toolchain.cmake -DPLATFORM=$platform
        stop
        cmake --build . --config Release
        mv_built_lib $platform 'libleveldb'
        echo ''
    done
    if [[ -e $lvdb_source/build ]]; then rm -rf $lvdb_source/build; fi
}

function make_framework() {
    cd $output

    mkdir iOS-lib
    mv libz-OS64 iOS-lib
    mv libleveldb-OS64 iOS-lib

    mkdir MacOS-lib
    mv libz-MAC* MacOS-lib
    mv libleveldb-MAC* MacOS-lib

    mkdir Simulator-lib
    mv libz-SIMULATOR64 Simulator-lib
    mv libleveldb-SIMULATOR64 Simulator-lib

    cd iOS-lib
    cp libz-OS64/libz.a libz.a
    cp libleveldb-OS64/libleveldb.a libleveldb.a
    cd ..

    cd MacOS-lib
    lipo -create libz-MAC/libz.a libz-MAC_ARM64/libz.a -output libz.a
    lipo -create libleveldb-MAC/libleveldb.a libleveldb-MAC_ARM64/libleveldb.a -output libleveldb.a
    cd ..

    cd Simulator-lib
    cp libz-SIMULATOR64/libz.a libz.a
    cp libleveldb-SIMULATOR64/libleveldb.a libleveldb.a
    cd ..

    xcodebuild -create-xcframework \
        -library iOS-lib/libz.a \
        -headers $libz_include \
        -library MacOS-lib/libz.a \
        -headers $libz_include \
        -library Simulator-lib/libz.a \
        -headers $libz_include \
        -output libz.xcframework
    
    xcodebuild -create-xcframework \
        -library iOS-lib/libleveldb.a \
        -headers $lvdb_include \
        -library MacOS-lib/libleveldb.a \
        -headers $lvdb_include \
        -library Simulator-lib/libleveldb.a \
        -headers $lvdb_include \
        -output libleveldb.xcframework
}

# ########## ########## ########## ########## ########## ########## ########## #

prepare
build_libz
build_libleveldb
make_framework

open $output
