#!/bin/bash

# 根目录 
baseDir=$1

# 程序安装目录
prefixDir=$2

# 检查是否安装了mysql

if (rpm -qa|grep mysql)
then
  # 有就先进行卸载，普通删除模式
  rpm -e mysql
fi

# 检查系统是否默认安装了mariadb
mariadb=$(rpm -qa|grep mariadb)
if [[ -n $mariadb ]]
then
  rpm -e --nodeps $mariadb
fi

# 定义依赖安装包数组
deps=(gcc gcc-c++ cmake openssl openssl-devel ncurses-devel autoconf)

#遍历安装依赖
for dep in $deps
do
  if [[ -z $(command -v $dep) ]]
  then   
    yum install -y $dep
    if [[ $? != 0 ]]
    then
      echo "安装依赖失败"
      exit
    fi
  fi
done

# 检测是否安装了expect
if [[ -z $(command -v expect)  ]]
then
    bash $baseDir"/libs/expect/expect.sh" "$baseDir" "$prefixDir"    
fi
