#!/bin/bash

# ==============================================================================
#   機能
#     リモートメンテナンス共通ツール
#   構文
#     . /usr/local/sbin/remote_maint_common.sh
#
#   Copyright (c) 2012-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 変数定義
######################################################################
# ユーザ変数
. /usr/local/etc/remote_maint_common_conf.sh
if [ $? -ne 0 ];then exit $?;fi

# プログラム内部変数
SSH_CMD="ssh_cmd.sh"
IFACE_STATUS="iface_status.pl"
CMD_STATUS_WAIT="cmd_status_wait.sh"

######################################################################
# 関数定義 (メインルーチン呼出し)
######################################################################
INIT_HOST_STAT() {
	unset host_1_alive
	unset host_2_alive
	unset host_1_mount
	unset host_2_mount
	unset host_active
	unset host_standby
	unset host_fqdn_active
	unset host_fqdn_standby
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		if [ ! "${host_fqdn_1[${i}]}" = "" ];then
			HOST_WAIT ${host_fqdn_1[${i}]} ${RETRY_NUM_HOST_ALIVE} up >/dev/null && host_1_alive[${i}]=1
		fi
		if [ ! "${host_fqdn_2[${i}]}" = "" ];then
			HOST_WAIT ${host_fqdn_2[${i}]} ${RETRY_NUM_HOST_ALIVE} up >/dev/null && host_2_alive[${i}]=1
		fi
		# host_1 とhost_2 のうち、両方とも生きている場合
		if [ \( "${host_1_alive[${i}]}" = "1" \) -a \( "${host_2_alive[${i}]}" = "1" \) ];then
			if [ ! "${share_fs_dir[${i}]}" = "" ];then
				SSH_IS_MOUNT ${host_fqdn_1[${i}]} ${share_fs_dir[${i}]} 2>/dev/null && host_1_mount[${i}]=1
				SSH_IS_MOUNT ${host_fqdn_2[${i}]} ${share_fs_dir[${i}]} 2>/dev/null && host_2_mount[${i}]=1
				if [ \( "${host_1_mount[${i}]}" = "1" \) -a \( "${host_2_mount[${i}]}" = "1" \) ];then
					echo "-W Both hosts mounting \"${share_fs_dir[${i}]}\" -- ${host_fqdn_1[${i}]}, ${host_fqdn_2[${i}]}" 1>&2
					# host_1 とhost_2 のうち、両方とも生きていないと見なす
					host_1_alive[${i}]=0
					host_2_alive[${i}]=0
				elif [ \( ! "${host_1_mount[${i}]}" = "1" \) -a \( ! "${host_2_mount[${i}]}" = "1" \) ];then
					echo "-W Both hosts NOT mounting \"${share_fs_dir[${i}]}\" -- ${host_fqdn_1[${i}]}, ${host_fqdn_2[${i}]}" 1>&2
					# host_1 とhost_2 のうち、両方とも生きていないと見なす
					host_1_alive[${i}]=0
					host_2_alive[${i}]=0
				elif [ "${host_1_mount[${i}]}" = "1" ];then
					host_active[${i}]=${host_1[${i}]}
					host_standby[${i}]=${host_2[${i}]}
					host_fqdn_active[${i}]=${host_fqdn_1[${i}]}
					host_fqdn_standby[${i}]=${host_fqdn_2[${i}]}
				elif [ "${host_2_mount[${i}]}" = "1" ];then
					host_active[${i}]=${host_2[${i}]}
					host_standby[${i}]=${host_1[${i}]}
					host_fqdn_active[${i}]=${host_fqdn_2[${i}]}
					host_fqdn_standby[${i}]=${host_fqdn_1[${i}]}
				fi
			else
				host_active[${i}]=${host_1[${i}]}
				host_standby[${i}]=${host_2[${i}]}
				host_fqdn_active[${i}]=${host_fqdn_1[${i}]}
				host_fqdn_standby[${i}]=${host_fqdn_2[${i}]}
			fi
		# host_1 のみ生きている場合
		elif [ "${host_1_alive[${i}]}" = "1" ];then
			if [ ! "${host_fqdn_2[${i}]}" = "" ];then
				echo "-W Host NOT alive -- ${host_fqdn_2[${i}]}" 1>&2
			fi
			if [ ! "${share_fs_dir[${i}]}" = "" ];then
				SSH_IS_MOUNT ${host_fqdn_1[${i}]} ${share_fs_dir[${i}]} 2>/dev/null && host_1_mount[${i}]=1
				if [ ! "${host_1_mount[${i}]}" = "1" ];then
					echo "-W Host NOT mounting \"${share_fs_dir[${i}]}\" -- ${host_fqdn_1[${i}]}" 1>&2
					# host_1 のみ生きていないと見なす
					host_1_alive[${i}]=0
				else
					host_active[${i}]=${host_1[${i}]}
					host_fqdn_active[${i}]=${host_fqdn_1[${i}]}
				fi
			else
				host_active[${i}]=${host_1[${i}]}
				host_fqdn_active[${i}]=${host_fqdn_1[${i}]}
			fi
		# host_2 のみ生きている場合
		elif [ "${host_2_alive[${i}]}" = "1" ];then
			if [ ! "${host_fqdn_1[${i}]}" = "" ];then
				echo "-W Host NOT alive -- ${host_fqdn_1[${i}]}" 1>&2
			fi
			if [ ! "${share_fs_dir[${i}]}" = "" ];then
				SSH_IS_MOUNT ${host_fqdn_2[${i}]} ${share_fs_dir[${i}]} 2>/dev/null && host_2_mount[${i}]=1
				if [ ! "${host_2_mount[${i}]}" = "1" ];then
					echo "-W Host NOT mounting \"${share_fs_dir[${i}]}\" -- ${host_fqdn_2[${i}]}" 1>&2
					# host_2 のみ生きていないと見なす
					host_2_alive[${i}]=0
				else
					host_active[${i}]=${host_2[${i}]}
					host_fqdn_active[${i}]=${host_fqdn_2[${i}]}
				fi
			else
				host_active[${i}]=${host_2[${i}]}
				host_fqdn_active[${i}]=${host_fqdn_2[${i}]}
			fi
		# host_1 とhost_2 のうち、両方とも生きていない場合
		else
			echo "-W Both hosts NOT alive -- ${host_fqdn_1[${i}]}, ${host_fqdn_2[${i}]}" 1>&2
		fi
	done
}

SHOW_HOST_STAT() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		echo
		echo "-I HOST_STAT の表示(host_group[${i}]=${host_group[${i}]})を開始します"
		echo "  host_1[${i}]=${host_1[${i}]}"
		echo "  host_2[${i}]=${host_2[${i}]}"
		echo "  host_1_alive[${i}]=${host_1_alive[${i}]}"
		echo "  host_2_alive[${i}]=${host_2_alive[${i}]}"
		echo "  host_1_mount[${i}]=${host_1_mount[${i}]}"
		echo "  host_2_mount[${i}]=${host_2_mount[${i}]}"
		echo "  host_fqdn_1[${i}]=${host_fqdn_1[${i}]}"
		echo "  host_fqdn_2[${i}]=${host_fqdn_2[${i}]}"
		echo "  host_active[${i}]=${host_active[${i}]}"
		echo "  host_standby[${i}]=${host_standby[${i}]}"
		echo "  host_fqdn_active[${i}]=${host_fqdn_active[${i}]}"
		echo "  host_fqdn_standby[${i}]=${host_fqdn_standby[${i}]}"
	done
}

######################################################################
# 関数定義 (非メインルーチン呼出し)
######################################################################
SSH() {
	host_fqdn="$1"
	cmd_line="$2"
	ssh ${SSH_OPTIONS} ${host_fqdn} "${cmd_line}"
}

SSH_IS_MOUNT() {
	host_fqdn="$1"
	mnt="$2"
	SSH ${host_fqdn} "LANG=C mount 2>&1 | grep -q \"^[^ ]\\{1,\\} on ${mnt} \""
}

SSH_CMD() {
	hosts_fqdn="$1"
	cmd_line="$2"
	${SSH_CMD} -E "${SSH_OPTIONS}" "${hosts_fqdn}" "${cmd_line}"
}

SCP() {
	src="$1"
	dest="$2"
	scp ${SCP_OPTIONS} -p "${src}" "${dest}" >/dev/null
}

HOST_WAIT() {
	host_fqdn="$1"
	retry_num="$2"
	status="$3"
	${IFACE_STATUS} wait -t ${retry_num} ${host_fqdn} ${status}
}

CMD_WAIT() {
	host_fqdn="$1"
	retry_num="$2"
	status="$3"
	cmd_line="$4"
	${CMD_STATUS_WAIT} -t ${retry_num} -S "${SSH_OPTIONS}" -H ${host_fqdn} "${status}" "${cmd_line}"
}

