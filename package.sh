#!/bin/sh
set -e

# compile for version
make
if [ $? -ne 0 ]; then
    echo "make error"
    exit 1
fi

frp_version=`./bin/frps --version`
echo "build version: $frp_version"

# cross_compiles
make -f ./Makefile.cross-compiles

rm -rf ./release/packages
mkdir -p ./release/packages

# 只保留 Android 平台
os_all='android'
# 只保留 ARM 架构
arch_all='arm arm64'
# 只保留基本后缀（无额外后缀）
extra_all='_'

cd ./release

for os in $os_all; do
    for arch in $arch_all; do
        for extra in $extra_all; do
            suffix="${os}_${arch}"
            
            # 特殊处理 ARMv7 架构
            if [ "$arch" = "arm" ]; then
                suffix="${os}_arm_v7"
            fi
            
            frp_dir_name="frp_${frp_version}_${suffix}"
            frp_path="./packages/frp_${frp_version}_${suffix}"

            # Android 属于非 Windows 系统
            if [ ! -f "./frpc_${suffix}" ]; then
                echo "frpc_${suffix} not found, skipping"
                continue
            fi
            if [ ! -f "./frps_${suffix}" ]; then
                echo "frps_${suffix} not found, skipping"
                continue
            fi
            
            mkdir -p ${frp_path}
            mv ./frpc_${suffix} ${frp_path}/frpc
            mv ./frps_${suffix} ${frp_path}/frps
            cp ../../LICENSE ${frp_path}
            cp -f ../../conf/frpc.toml ${frp_path}
            cp -f ../../conf/frps.toml ${frp_path}

            # 打包
            cd ./packages
            tar -zcf ${frp_dir_name}.tar.gz ${frp_dir_name}
            cd ..
            rm -rf ${frp_path}
        done
    done
done

cd -
