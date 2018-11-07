#!/bin/bash
##Author:fangyuanzheng<fyuanz_2010@163.com>
##lttng-ust是用户空间跟踪库，测试点是检查包的版本和源

#####加载外部文件################ 
cd ../../../../utils
source ./sys_info.sh
source ./sh-test-lib
cd -

#############################  Test user id       #########################
! check_root && error_msg "Please run this script as root."

######################## Environmental preparation   ######################
version="2.4.1"
from_repo="epel"
case $distro in
    "centos")
         package="lttng-ust"
         install_deps "${package}" 
         print_info $? lttng-ust
         ;;
    "ubuntu"|"debian"|"opensuse")
         package="liblttng-ust0"
         install_deps "${package}"
         print_info $? lttng-ust
         ;;
    "fedora")
	 package="lttng-ust.aarch64"
	 install_deps "${package}"
         print_info $? lttng-ust
	 ;;


 esac
#######################  testing the step ###########################
# Check the package version && source
case $distro in
     "centos")
from=$(yum info $package | grep "From repo" | awk '{print $4}')
if [ "$from" = "$from_repo"  ];then
      print_info 0 repo_check
else
    rmflag=1
    if [ "$from" != "Estuary"  ];then
        yum remove -y $package
        yum install -y $package
        from=$(yum info $package | grep "From repo" | awk '{print $4}')
        if [ "$from" = "$from_repo"   ];then
            print_info 0 repo_check
        else
            print_info 1 repo_check
        fi
    fi
fi

vers=$(yum info $package | grep "Version" | awk '{print $3}')
if [ "$vers" = "$version"   ];then
      print_info 0 version
else
     print_info 1 version
fi
;;
     "ubuntu")
from=$(apt show $package |grep Source |awk '{print $2}')
print_info $? $from
vers=$(apt show $package | grep "Version" | awk '{print $2}')
print_info $? $vers
;;     
     "debian")
from=$(apt show $package |grep Source |awk '{print $2}'|head -1)
print_info $? $from
vers=$(apt show $package | grep "Version" | awk '{print $2}')
print_info $? $vers
;;
     "opensuse")
from=$(zypper info $package |grep "Repo"|awk '{print $3}')
print_info $? $from
vers=$(zypper info $package | grep "Version" | awk '{print $3}')
print_info $? $vers
;;

     "fedora")
from=$(yum info $package |grep "Repo" |awk '{print $3}')
print_info $? $from
vers=$(yum info $package | grep "Version" | awk '{print $3}')
print_info $? $vers
;;

esac
######################  environment  restore ##########################
# Remove package
case $distro in
     "centos"|"ubuntu"|"fedora"|"debian"|"opensuse")
     remove_deps "${package}"
     print_info $? remove_lttng-ust
;;
esac
