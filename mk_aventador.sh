#!/bin/bash

HERE=`pwd`
set_commonvars()
{
	LOGDIR=${HERE}/Logs
	[ ! -d ${LOGDIR} ] && mkdir ${LOGDIR} 
	DTB_DIR=${BOARD}_dtb
	[ ! -d ${DTB_DIR} ] && mkdir ${DTB_DIR} 
	SH_SOURCES="Sh_P2214163_nV-4.6.3_r32.7.3-00"
	SH_GIT_SOURCES="https://github.com/StoneHEX/${SH_SOURCES}.git"
	CROSS_COMPILER_SERVER="releases.linaro.org"
	CROSS_COMPILER="gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu"
	CROSS_COMPILER_ARCHIVE="${CROSS_COMPILER}.tar.xz"
	TOOLCHAIN_PREFIX="${HERE}/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-"
	TEGRA_KERNEL_OUT="${HERE}/${SH_SOURCES}/${BOARD}_build"
	DTSI_FOLDER="dtsi/${BOARD}"
}

set_nanovars()
{
	JETPACK="${HERE}/../JetPack_4.6.3_Linux_JETSON_NANO_TARGETS/Linux_for_Tegra"
	JETPACK_ROOTFS="${JETPACK}/rootfs"
	DTB_FILE="tegra210-p3448-0002-aventador-0000-b00.dtb"
	SOURCE_PINMUX="tegra210-aventador-pinmux.dtsi"
	SOURCE_GPIO="tegra210-aventador-gpio-default.dtsi"
	SOURCE_PADV="nano_unused"
}

set_xaviervars()
{
	JETPACK="${HERE}/../JetPack_4.6.3_Linux_JETSON_XAVIER_NX_TARGETS/Linux_for_Tegra"
	JETPACK_ROOTFS="${JETPACK}/rootfs"
	DTB_FILE="tegra194-p3668-aventador-0000.dtb"
	SOURCE_PINMUX="tegra19x-aventador-00-pinmux.dtsi"
	SOURCE_GPIO="tegra19x-aventador-00-gpio-default.dtsi"
	SOURCE_PADV="tegra19x-aventador-00-padvoltage-default.dtsi"
	PINMUX_EXE_XAVIER="${JETPACK}/kernel/pinmux/t19x"
}


exit_error()
{
	echo "Error on step $1"
	exit -1
}

usage()
{
        echo "Usage: $0 -o [<kernel> <modules> <dtbs> <all> <cleanup>] -b [<nano> <xavier>]" 1>&2;
        exit 1;
}


check_for_sources()
{
	cd ${HERE}
	if [ ! -d ${SH_SOURCES} ]; then
		git clone  ${SH_GIT_SOURCES}
	fi
	if [ ! -d ${CROSS_COMPILER} ]; then
		echo "Cross compiler not found,downloading ${CROSS_COMPILER_ARCHIVE}"
		wget http://${CROSS_COMPILER_SERVER}/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
		if [ $? != "0" ]; then
			echo "${CROSS_COMPILER_ARCHIVE} not found on server ${CROSS_COMPILER_SERVER}"
			exit
		fi
		tar xf ${CROSS_COMPILER_ARCHIVE}
	fi
}

set_environment_vars()
{
	echo "KERNEL_SOURCES=${HERE}/${SH_SOURCES}" > ${BOARD}.env
	echo "TOOLCHAIN_PREFIX=${TOOLCHAIN_PREFIX}" >> ${BOARD}.env
	echo "PROCESSORS=16" >> ${BOARD}.env
	echo "TEGRA_KERNEL_OUT=${TEGRA_KERNEL_OUT}" >> ${BOARD}.env
	echo "JETPACK=${JETPACK}" >> ${BOARD}.env
	echo "JETPACK_ROOTFS=${JETPACK_ROOTFS}" >> ${BOARD}.env
	echo "DTB_FILE=${DTB_FILE}" >> ${BOARD}.env
	echo "DTB_FULL_PATH=${HERE}/${DTB_DIR}/${DTB_FILE}" >> ${BOARD}.env
	echo "DTSI_FOLDER=${HERE}/dtsi/${BOARD}">> ${BOARD}.env
	echo "SOURCE_PINMUX=${SOURCE_PINMUX}"  >> ${BOARD}.env
	echo "SOURCE_GPIO=${SOURCE_GPIO}"  >> ${BOARD}.env
	echo "SOURCE_PADV=${SOURCE_PADV}"  >> ${BOARD}.env
	. ./${BOARD}.env
}

setup_nano_dtbs()
{
		cp ${DTSI_FOLDER}/${SOURCE_PINMUX} ${HERE}/${SH_SOURCES}/hardware/nvidia/platform/t210/porg/kernel-dts/porg-platforms/tegra210-aventador-0000-pinmux-p3448-0002-b00.dtsi
		cp ${DTSI_FOLDER}/${SOURCE_GPIO} ${HERE}/${SH_SOURCES}/hardware/nvidia/platform/t210/porg/kernel-dts/porg-platforms/tegra210-aventador-0000-gpio-p3448-0002-b00.dtsi
}

setup_xavier_dtbs()
{
	cp ${DTSI_FOLDER}/${SOURCE_PINMUX} ${PINMUX_EXE_XAVIER}/.
	cp ${DTSI_FOLDER}/${SOURCE_GPIO} ${PINMUX_EXE_XAVIER}/.
	cp ${DTSI_FOLDER}/${SOURCE_PADV} ${PINMUX_EXE_XAVIER}/.
	cd ${PINMUX_EXE_XAVIER}
	echo "Running pimnux from ${SOURCE_PINMUX} and ${SOURCE_GPIO}"

	python pinmux-dts2cfg.py \
		--pinmux                                        \
		addr_info.txt gpio_addr_info.txt por_val.txt    \
		${SOURCE_PINMUX}                                \
		${SOURCE_GPIO}                                  \
		1.0                                             \
	> ${JETPACK}/bootloader/t186ref/BCT/tegra19x-mb1-pinmux-p3668-a01.cfg

	echo "Running padvoltage from ${SOURCE_PADV}"
	python pinmux-dts2cfg.py --pad pad_info.txt ${SOURCE_PADV}  1.0 > ${JETPACK}/bootloader/t186ref/BCT/tegra19x-mb1-padvoltage-p3668-a01.cfg
	cd ${HERE}
}

build()
{
	setup_${BOARD}_dtbs
	cd ${KERNEL_SOURCES}
	#STEPS="tegra_defconfig zImage modules dtbs modules_install"
	for i in ${STEPS}; do
		echo "Running $i"
		if [ "$i" == "modules_install" ]; then
			sudo make -C kernel/kernel-4.9/ ARCH=arm64 O=$TEGRA_KERNEL_OUT LOCALVERSION=-tegra INSTALL_MOD_PATH=$JETPACK_ROOTFS CROSS_COMPILE=${TOOLCHAIN_PREFIX} -j${PROCESSORS} --output-sync=target $i > ${LOGDIR}/log.$i 2>&1
		else
			make -C kernel/kernel-4.9/ ARCH=arm64 O=$TEGRA_KERNEL_OUT LOCALVERSION=-tegra CROSS_COMPILE=${TOOLCHAIN_PREFIX} -j${PROCESSORS} --output-sync=target $i > ${LOGDIR}/log.$i 2>&1
		fi
		if [ ! "$?" == 0 ]; then
			exit_error $i
		fi
	done
	cd ${HERE}
}

copy_results()
{
	cd ${JETPACK}
	# Copy device tree generated
	echo "Copying to ${BOARD} sdk"
	cp ${TEGRA_KERNEL_OUT}/arch/arm64/boot/Image kernel/
	cp ${TEGRA_KERNEL_OUT}/arch/arm64/boot/dts/${DTB_FILE} kernel/dtb/
	echo "Copying to ${BOARD}_dtb folder"
	cp ${TEGRA_KERNEL_OUT}/arch/arm64/boot/dts/${DTB_FILE} ${DTB_FULL_PATH}
}

# MAIN
while getopts ":b::o:" opts; do
        case "${opts}" in
                o)
                        OPTIONS="1"
                        case "${OPTARG}" in
                                kernel)
                                        STEPS="tegra_defconfig zImage"
                                        ;;
                                modules)
                                        STEPS="tegra_defconfig modules modules_install"
                                        ;;
                                dtbs)
                                        STEPS="tegra_defconfig dtbs"
                                        ;;
                                all)
                                        STEPS="tegra_defconfig zImage modules dtbs modules_install"
                                        ;;
                                cleanup)
                                        STEPS="distclean mrproper"
                                        ;;
                                *)
                                        echo "Invalid ops ${OPTARG}"
                                        usage
                                        ;;
                        esac
                        ;;
		b)
			BOARD=${OPTARG}
			case "${BOARD}" in
				nano)
					set_commonvars
					set_nanovars
					;;
				xavier)
					set_commonvars
					set_xaviervars
					;;
				*)
					usage
					;;
			esac
                        ;;
		*)
                        usage
                        ;;
        esac
done
if [ -z "${OPTIONS}" ]; then
    usage
fi
if [ -z "${BOARD}" ]; then
    usage
fi

echo "Running on ${BOARD}"
check_for_sources
set_environment_vars
build
copy_results

