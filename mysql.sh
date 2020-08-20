#!/bin/bash

# 获取压缩包的路径
baseDir=$(pwd)

# 加载配置文件
source "${baseDir}/mysql.conf"

# 引入函数库
source "${baseDir}/libs/func.sh"

echo -e  "\033[33m+----------------------------------------------------------------------+\033[0m"
echo -e  "\033[33m|       mysqld v1.0.0 for Centos Linux Server, Written by Licess       |\033[0m"
echo -e  "\033[33m+----------------------------------------------------------------------+\033[0m"
echo -e  "\033[33m+                         mysql 5.6 5.7 8.0                            +\033[0m"
echo -e  "\033[33m+----------------------------------------------------------------------+\033[0m"
echo -e  "\033[33m+           A tool to auto-compile & install Mysql on Linux            +\033[0m"
echo -e  "\033[33m+----------------------------------------------------------------------+\033[0m"

# 赋予 sh,ext文件执行权限
shExt=$(find ./ -regextype posix-extended -regex ".*.(sh|ext)$");
for i in $shExt
do
	chmod u+x $i
done

# 输入安装目录
echo "-----------------------------------"
echo "-----------------------------------"
echo -e "\033[33mPlease enter the installation directory (default /usr/local)\033[0m"


read prefixDir

# 判断是否直接回车
if [[ -z $prefixDir ]]
then
    # 默认路径
    prefixDir=$prefixDirDefault
fi

# mysql安装路径
installUrl="${prefixDir}/${mysqlInstallName}"

echo -e "\033[33mYou have select ${installUrl}\033[0m"


echo "-----------------------------------"
echo "-----------------------------------"
echo -e "\033[33mSet MySQL password at least 8 letters and numbers (default ${passwdDefault})\033[0m"

while read setPasswd
do
    if [[ -n $( echo "$setPasswd"|grep -P "^(?=.*[0-9])(?=.*[a-zA-Z])(.{8,})$") ]]
    then
        break
    elif [[ -z $setPasswd ]]
    then
        setPasswd=$passwdDefault
        break
    else
        echo -e  "\033[33mThe password must contain more than 8 letters and numbers\033[0m"
    fi
done

echo "-----------------------------------"
echo "-----------------------------------"

##################################选择mysql版本#######################################

echo -e  "\033[33mPlease select MySQL version?\033[0m"

#关联数字，先定义再赋值
declare -A selectMysqlVer
selectMysqlVer[0]="Install MySQL 5.6 (default)" 
selectMysqlVer[1]="Install MySQL 5.7" 
selectMysqlVer[2]="Install MySQL 8.0" 
selectMysqlVer[3]="NO NOT Install MySQL"

count=1

# 数据库安装有*个选项
echo -e "\033[33mYou have ${#selectMysqlVer[@]} options for your DataBase install\033[0m"

for val in "${selectMysqlVer[@]}"
do
    if [[ $count -eq 1 ]]
    then
        choice=1
    else
        choice="${choice}, ${count}"
    fi
    echo "${count}: ${val}"
    let count++
done

# 输入你的选择
echo -e "\033[33mEnter your choice ($choice):\033[0m"

selectMysql=("mysql5_6" "mysql5_7" "mysql8_0")

while read select
do
    # 验证输入是否正确
    if [[ $select -gt 0 ]] && [[ $select -le ${#selectMysqlVer[@]} ]]
    then
        if [[ $select -eq ${#selectMysqlVer[@]} ]]
        then
            # 取消mysql安装
            echo -e "\033[31mYou have canceled MySQL installation\033[0m"
            exit 1
        else
            # 选择mysql版本
            ((select--))
            selectMysqlFunc "${selectMysql[$select]}"
        fi
        break
    elif [[ -z $select ]]
    then
        selectMysqlFunc "${selectMysql[0]}"
        break
    else
        echo -e "\033[31mRe enter your choice ($choice)\033[0m"
    fi

done

##################################选择源码包###########################################

getCodeFunc $baseDir "${baseDir}/source/mysql" $mysqlDown ".*mysql.*${mysqlVer}[^/]*\.tar[\.(xg)z]*" "Mysql"
mysql_name=$getCodeReturn


# 创建安装目录
if [[ ! -d $installUrl ]]
then
   	mkdir $installUrl 
    if [[ $? != 0 ]]
    then
      echo -e "\033[31mFailed to create installation directory, check permissions\033[0m"
      exit
    fi
fi

# 删除tar目录下解压文件
if [[  -d "${baseDir}/tar" ]]
then
    mkdir "${baseDir}/tar"
else
    rm $baseDir"/tar/*" -rf
fi

# 解压
if [[ ${mysql_name##*.} = "xz" ]]
then
	# 判断mysql是否为xz后缀压缩文件
	mysql_xz=${mysql_name%.*}
	xz -d $mysql_name
	tar -xvf $mysql_xz -C $installUrl --strip-components 1

elif [[ ${mysql_name##*.} = "gz" ]]
then
	# 判断mysql是否为gz后缀压缩文件
	tar -zxvf $mysql_name -C $installUrl --strip-components 1

elif [[ ${mysql_name##*.} = "tar" ]]
then
	# 判断mysql是否为tar后缀压缩文件
	tar -xvf $mysql_name -C $installUrl --strip-components 1
else
	echo "mysql源码包压缩格式不正确"
fi

# 判断是否解压成功
if [[ $? == 0 ]]
then
    echo "解压成功"
  else
    echo "解压失败"
    exit 1
fi


# 检查并安装依赖
source $baseDir"/libs/deps.sh" "$baseDir" "$prefixDir"

# 创建mysql用户、用户组
groupadd mysql
useradd -r -s /sbin/nologin -g mysql mysql -d $installUrl

# 重新加载配置文件
source "${baseDir}/mysql.conf"

# 创建mysql数据目录
if [[ -d $mysql_data_dir ]]
then
  rm $mysql_data_dir -rf
else
  mkdir $mysql_data_dir
fi

# 创建日志目录
if [[ ! -d $mysql_logs_dir ]]
then
  mkdir $mysql_logs_dir
  touch "${mysql_logs_dir}/error.log"
fi

# 配置环境变量
if [[ ! $(grep "PATH=\$PATH:${installUrl}/bin" /etc/profile) ]]
then
  echo "PATH=\$PATH:${installUrl}/bin" >> /etc/profile
  echo "export PATH" >> /etc/profile
fi

# 使环境变量生效
source /etc/profile

# 更改mysql安装目录权限
chown -R mysql.mysql $installUrl

# 初始化数据库
if  [[ $(echo $mysqlVer|awk '{print ($0/5.6)==1}') -eq 1 ]]
then
	# mysql5.6版本
	cd $installUrl
	installInfo=$(./scripts/mysql_install_db --user=mysql --datadir=$mysql_data_dir)

elif  [[ $(echo $mysqlVer|awk '{print ($0/5.7)==1}') -eq 1 ]]
then
	# mysql 5.7版本
	installInfo=$(mysqld --initialize --user=mysql --basedir=$installUrl --datadir=$mysql_data_dir --pid-file=$mysql_data_dir/mysql.pid 2>&1 | grep "localhost")

elif  [[ $(echo $mysqlVer|awk '{print ($0/8.0)==1}') -eq 1 ]]
then
	# mysql 8.0版本
	installInfo=$(mysqld --initialize --user=mysql --basedir=$installUrl --datadir=$mysql_data_dir --pid-file=$mysql_data_dir/mysql.pid 2>&1 | grep "localhost")
else
	echo "mysql初始化失败"
	exit
fi

initPasswd=$(getPasswdFunc)
echo "初始密码为$initPasswd"

# 更改配置文件安装目录，重定向输出
sed -e "s# &basedir#$installUrl#" "$baseDir/libs/mysql/my.cnf" > /etc/my.cnf

# 复制启动脚本并重命名
cp "$installUrl/support-files/mysql.server" /etc/init.d/mysqld

service mysqld start

# 增加systemctl服务管理
\cp -rf $baseDir"/libs/mysql/mysqld.service" /etc/systemd/system/mysqld.service
# 重新加载服务配置文件
systemctl daemon-reload
# 设置开机自启动
systemctl enable mysqld
# 启动mysql
systemctl start mysqld

#进行安全配置向导
if [[ $? -eq 0  ]]
then
 	if [[ $(echo $mysqlVer|awk '{print ($0/5.6)==1}') -eq 1 ]] 
	then
		# mysql5.6版本
    	expect "$baseDir/libs/mysql/mysql5_6.ext" "$initPasswd" "$setPasswd" 

	elif [[ $(echo $mysqlVer|awk '{print ($0/5.7)==1}') -eq 1 ]] 
	then
		# mysql5.7版本
    	expect "$baseDir/libs/mysql/mysql5_7.ext" "$initPasswd" "$setPasswd" 
	elif [[ $(echo $mysqlVer|awk '{print ($0/8.0)==1}') -eq 1 ]] 
	then
    	expect "$baseDir/libs/mysql/mysql8_0.ext" "$initPasswd" "$setPasswd" 
	fi
fi
