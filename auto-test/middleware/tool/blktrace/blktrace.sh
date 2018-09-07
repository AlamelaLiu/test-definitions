
#!/bin/bash 
# Copyright (C) 2018-9-6, estuary Limited.
##Author:mahongxin
##blktrace��һ���û�̬�Ĺ��ߣ������ռ�����IO��Ϣ�е�IO���е����豸��ʱ����ϸ��Ϣ
set -x
#### Test user id################
check_root
####�����ⲿ�ļ�################
cd ../../../../utils
source       ./sys_info.sh
source       ./sh-test-lib
cd -
##################### Environmental preparation  #######################
pkgs="blktrace"
install_deps "${pkgs}"
print_info $? install-blktrace
 
#######################  testing the step ###########################

# �Խ���sdaд��������ӡ��Ϣ
blktrace -d /dev/sda -w 5
print_info $? default_file

###��blktrace�ɼ�����Ϣ��blkparse�����ô�ӡ����#####
blktrace -d /dev/sda -w 5 -o - |blkparse -i -
print_info $? display

###��blktrace�ɼ�����Ϣ��blkparse�����ô�ӡ��ָ���ļ�trace��#####
blktrace -d /dev/sda -w 10 -o trace | blkparse -i -
print_info $? output

####��trace�ļ���Ϊblkparse���������������Ļ#####
blkparse -i trace
print_info $? data_analysis



######################  environment  restore ##########################
remove_deps "${pkgs}"
print_info $? remove

rm -rf trace.blktrace.*
rm -rf sda.blktrace.*
