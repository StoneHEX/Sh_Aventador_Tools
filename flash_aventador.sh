#!/bin/bash

usage()
{
        echo "Usage: $0 -o [<reuse> <dtbs> <all>] -b [<nano> <xavier>]" 1>&2;
        exit 1;
}

create_common_conf()
{
	echo "# Copyright (c) 2019-2020, StoneHEX.  All rights reserved." > ${JETPACK}/${BOARD}_aventador.conf
	echo "#" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "# Redistribution and use in source and binary forms, with or without" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "# modification, are permitted provided that the following conditions" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "# are met:" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "#  * Redistributions of source code must retain the above copyright" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "#    notice, this list of conditions and the following disclaimer." >> ${JETPACK}/${BOARD}_aventador.conf
	echo "#  * Redistributions in binary form must reproduce the above copyright" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "#    notice, this list of conditions and the following disclaimer in the" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "#    documentation and/or other materials provided with the distribution." >> ${JETPACK}/${BOARD}_aventador.conf
	echo "#  * Neither the name of NVIDIA CORPORATION nor the names of its" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "#    contributors may be used to endorse or promote products derived" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "#    from this software without specific prior written permission." >> ${JETPACK}/${BOARD}_aventador.conf
	echo "#" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL," >> ${JETPACK}/${BOARD}_aventador.conf
	echo "# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO," >> ${JETPACK}/${BOARD}_aventador.conf
	echo "# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE." >> ${JETPACK}/${BOARD}_aventador.conf
	echo "" >> ${JETPACK}/${BOARD}_aventador.conf
}

create_nano_conf()
{
	echo "EMMC_CFG=flash_l4t_t210_emmc_p3448.xml;" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "BLBlockSize=1048576;" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "source \"\${LDK_DIR}/p3448-0000.conf.common\";" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "T21BINARGS=\"--bins \\\"EBT cboot.bin; \"" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "CMDLINE_ADD=\"console=ttyS0,115200n8 console=tty0 fbcon=map:0 net.ifnames=0 sdhci_tegra.en_boot_part_access=1\";" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "ROOTFSSIZE=14GiB;" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "VERFILENAME=\"emmc_bootblob_ver.txt\";" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "OTA_BOOT_DEVICE=\"/dev/mmcblk0boot0\";" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "OTA_GPT_DEVICE=\"/dev/mmcblk0boot1\";" >> ${JETPACK}/${BOARD}_aventador.conf
}

create_xavier_conf()
{
        echo "source \"\${LDK_DIR}/p3668.conf.common\";" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "" >> ${JETPACK}/${BOARD}_aventador.conf
        echo "EMMC_CFG=flash_l4t_t194_spi_emmc_p3668.xml;" >> ${JETPACK}/${BOARD}_aventador.conf
        echo "EMMCSIZE=17179869184;" >> ${JETPACK}/${BOARD}_aventador.conf
	echo "" >> ${JETPACK}/${BOARD}_aventador.conf
        echo "# Rootfs A/B:" >> ${JETPACK}/${BOARD}_aventador.conf
        echo "if [[ \"\${ROOTFS_AB}\" == 1 && \"\${ROOTFS_ENC}\" == \"\" ]]; then" >> ${JETPACK}/${BOARD}_aventador.conf
        echo "	rootfs_ab=1;" >> ${JETPACK}/${BOARD}_aventador.conf
        echo "	EMMC_CFG=flash_l4t_t194_spi_emmc_p3668_rootfs_ab.xml;" >> ${JETPACK}/${BOARD}_aventador.conf
        echo "# Disk encryption support:" >> ${JETPACK}/${BOARD}_aventador.conf
        echo "elif [[ \"\${ROOTFS_AB}\" == \"\" && \"\${ROOTFS_ENC}\" == 1 ]]; then" >> ${JETPACK}/${BOARD}_aventador.conf
        echo "	disk_enc_enable=1;" >> ${JETPACK}/${BOARD}_aventador.conf
        echo "	EMMC_CFG=flash_l4t_t194_spi_emmc_p3668_enc_rfs.xml;" >> ${JETPACK}/${BOARD}_aventador.conf
        echo "# Rootfs A/B + Disk encryption support:" >> ${JETPACK}/${BOARD}_aventador.conf
        echo "elif [[ \"\${ROOTFS_AB}\" == 1 && \"\${ROOTFS_ENC}\" == 1 ]]; then" >> ${JETPACK}/${BOARD}_aventador.conf
        echo "	rootfs_ab=1;" >> ${JETPACK}/${BOARD}_aventador.conf
        echo "	disk_enc_enable=1;" >> ${JETPACK}/${BOARD}_aventador.conf
        echo "	EMMC_CFG=flash_l4t_t194_spi_emmc_p3668_enc_rootfs_ab.xml;" >> ${JETPACK}/${BOARD}_aventador.conf
        echo "fi;" >> ${JETPACK}/${BOARD}_aventador.conf

}

while getopts ":b::o:" opts; do
case "${opts}" in
	o)
       		OPTIONS="1"
		case "${OPTARG}" in
			reuse)
                       		PARAM="-r"
				;;
			dtbs)
                       		PARAM="-r -k DTB"
				;;
			all)
                       		PARAM=""
				;;
			rcmboot)
                       		PARAM="--rcm-boot"
				;;
		esac
		;;
	b)
		BOARD=${OPTARG}
		case "${BOARD}" in
			nano)
				BOARD_OK=1
				;;
			xavier)
				BOARD_OK=1
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

if [ ! -f ${BOARD}.env ]; then
	echo "${BOARD}.env not present, run mk.sh first"
	exit 1
fi
. ./${BOARD}.env
create_common_conf
create_${BOARD}_conf

cd ${JETPACK}
echo "sudo ./flash.sh ${PARAM} -d ${DTB_FULL_PATH} ${BOARD}_aventador mmcblk0p1"
sudo ./flash.sh ${PARAM} -d ${DTB_FULL_PATH} ${BOARD}_aventador mmcblk0p1
