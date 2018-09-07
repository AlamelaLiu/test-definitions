#!/bin/bash
# Copyright (C) 2018-9-7, Estuary
# Author: wangsisi
# slabtop������ʵʱ�ķ�ʽ��ʾ�ںˡ�slab����������ϸ����Ϣ
:<<!
slabtop
����˵����
   --delay=n, -d n��ÿn�����һ����ʾ����Ϣ��Ĭ����ÿ3�룻
   --once, -o����ʾһ�κ��˳���
   --version, -V����ʾ�汾��
   --help����ʾ������Ϣ
!

! check_root && error_msg "Please run this script as root." 
source ../../../../utils/sys_info.sh
source ../../../../utils/sh-test-lib

###################  Environmental preparation  ######################
check_list="OBJS ACTIVE USE SLABS OBJ/SLAB CACHE SIZE NAME"

#####################    testing the step    ##########################
# run slabtop
for p in ${check_list};do
slabtop -o|egrep -i $p
print_info $? slabtop_${p}
done
slabtop -o|egrep -i "OBJ SIZE"
print_info $? slabtop_OBJ_SIZE

# adjust delay time
slabtop --delay=5 -o
print_info $? delay

# output one time
slabtop --once |tee log.txt 
count=$(grep -i OBJS  log.txt|wc -l )
if [ "$count" = "1" ]; then
   print_info 0 once
else
   print_info 1 once
fi

# check version
slabtop --version|grep -i "slabtop from"
print_info $? version

# help options
slabtop --help|grep -i "Usage"
print_info $? help
