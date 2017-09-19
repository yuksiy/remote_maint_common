#!/bin/bash

# 下記のサンプル定義で想定しているサーバのホスト名と用途は以下の通りです。
#   ホスト名        用途
#   --------------------------------------------------------
#   dns1,dns2       DNSサーバ#1,2  (HAクラスタ構成)
#   mail1,mail2     MAILサーバ#1,2 (HAクラスタ構成)
#   www1,www2       WEBサーバ#1,2  (HAクラスタ構成)
#   samba           SAMBAサーバ    (非HAクラスタ構成)
#   dns, mail, www  上記の各HAクラスタのサービスホスト名

# ユーザ変数
dns1=dns1.example.com   ; dns2=dns2.example.com
mail1=mail1.example.com ; mail2=mail2.example.com
www1=www1.example.com   ; www2=www2.example.com
samba=samba.example.com

unset host_group
unset host_1
unset host_2
unset host_fqdn_1
unset host_fqdn_2
unset share_fs
i=1 ; for host_group in ${HOST_GROUPS} ; do
	host_group[${i}]="${host_group}"
	host_1[${i}]="`echo \"${host_group}\" | awk -F',' '{print $1}'`"
	host_2[${i}]="`echo \"${host_group}\" | awk -F',' '{print $2}'`"
	case ${host_1[${i}]} in
	dns1|dns2|mail1|mail2|www1|www2|samba)
		:	# 何もしない
		;;
	*)
		echo "-E host_1 parameter of \"${host_group}\" is invalid -- \"${host_1[${i}]}\"" 1>&2
		exit 1
		;;
	esac
	case ${host_2[${i}]} in
	dns1|dns2|mail1|mail2|www1|www2|samba|"")
		:	# 何もしない
		;;
	*)
		echo "-E host_2 parameter of \"${host_group}\" is invalid -- \"${host_2[${i}]}\"" 1>&2
		exit 1
		;;
	esac

	host_fqdn_1[${i}]=${!host_1[${i}]}
	host_fqdn_2[${i}]=${!host_2[${i}]}
	case ${host_1[${i}]} in
	dns1|dns2)
		share_fs[${i}]="/dev/drbd2 /SHARE ext4 defaults,noatime,acl"
		;;
	mail1|mail2)
		share_fs[${i}]="/dev/drbd2 /SHARE ext4 defaults,noatime,acl"
		;;
	www1|www2)
		share_fs[${i}]="/dev/drbd2 /SHARE ext4 defaults,noatime,acl"
		;;
	esac
	i=`expr ${i} + 1`
done ; host_group_count=`expr ${i} - 1`

unset share_fs_dev
unset share_fs_dir
unset share_fs_type
unset share_fs_options
for (( i=1; i<=${host_group_count}; i++ )) ; do
	share_fs_dev[${i}]="`echo ${share_fs[${i}]} | awk -F' ' '{print $1}'`"
	share_fs_dir[${i}]="`echo ${share_fs[${i}]} | awk -F' ' '{print $2}'`"
	share_fs_type[${i}]="`echo ${share_fs[${i}]} | awk -F' ' '{print $3}'`"
	share_fs_options[${i}]="`echo ${share_fs[${i}]} | awk -F' ' '{print $4}'`"
done

REMOTE_UNAME="root"
SSH_KEYFILE="/root/.ssh/id_rsa_remote_maint"

SSH_OPTIONS="-i ${SSH_KEYFILE} -l ${REMOTE_UNAME}"
SCP_OPTIONS="-i ${SSH_KEYFILE}"

RETRY_NUM_HOST_ALIVE=3

