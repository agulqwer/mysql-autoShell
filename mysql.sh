#!/bin/bash

# 获取mysql初始密码函数

function getPasswd(){
 	if [[ $(echo $mysqlVer|awk '{print ($0/5.6)==1}') -eq 1 ]] 
	then
		# mysql 5.6版本
		echo ""
	elif [[ $(echo $mysqlVer|awk '{print ($0/5.7)==1}') -eq 1 ]] || [[ $(echo $mysqlVer|awk '{print ($0/8.0)==1}') -eq 1 ]]
	then
		# mysql 5.7版本 mysql 8.0版本

		if [[ -n $installInfo ]]
		then
			passwd=${installInfo#*password:}
			echo $passwd
		else
			mycnf=$(mysqld --verbose --help | grep -A 1 'Default options'|awk 'NR==2{print $0}')
			passwd=" "
			for cnf in $mycnf
			do
				if [[ -f $cnf ]]
				then
					logerror=$(cat $cnf|grep "log-error")
					logerror=${logerror#*=}
					if [[ -f $logerror ]]
					then
						passwd=$(cat $logerror|awk '/localhost/{print $0}')
						passwd=${passwd##*localhost:}
						echo $passwd
					fi
				fi

			done
		fi
	fi

}

# 赋予 sh,ext文件执行权限
shExt=$(find ./ -regextype posix-extended -regex ".*.(sh|ext)$");
for i in $shExt
do
	chmod u+x $i
done


# 获取压缩包的路径
baseDir=$(pwd)
echo "---------------------------"
echo "---------------------------"
echo "输入安装路径"
read prefixDir
installUrl=$prefixDir"/mysql"

echo "---------------------------"
echo "---------------------------"
echo "设置mysql密码（至少8位以上字母和数字组合）"

while read setPasswd
do
    if [[ -n $( echo "$setPasswd"|grep -P "^(?=.*[0-9])(?=.*[a-zA-Z])(.{8,})$") ]]
    then
        break
    else
        echo "密码必须包含8位以上的字母和数字"
    fi
done

echo "---------------------------"
echo "---------------------------"

# 查找mysql源码包

# 各版本mysql源码包下载地址
mysql5_6Down="https://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.48-linux-glibc2.12-x86_64.tar.gz"
mysql5_7Down="https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.30-linux-glibc2.12-x86_64.tar.gz"
mysql8_0Down="https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.20-linux-glibc2.12-x86_64.tar.xz"

echo "---------------------------"
echo "---------------------------"
echo "请选择mysql版本？"

mysqlVer=("mysql_5.6" "mysql_5.7" "mysql_8.0")

select i in ${mysqlVer[@]}
do
	case $i in
		"mysql_5.6")
			echo "选择mysql 5.6版本"
			mysqlVer=5.6

			# 搜索压缩包
			mysql_tar=($(find $baseDir -regex  ".*mysql.*5.6.*.tar[\.gz]*"))
			# mysql源码包下载路径
			mysqlDown=$mysql5_6Down

			break
			;;
		"mysql_5.7")
			echo "选择mysql 5.7版本"
			mysqlVer=5.7

			# 搜索压缩包
			mysql_tar=($(find $baseDir -regex  ".*mysql.*5.7.*.tar[\.gz]*"))

			# mysql源码包下载路径
			mysqlDown=$mysql5_7Down

			break
			;;
		"mysql_8.0")
			echo "选择mysql 8.0版本"
			mysqlVer=8.0

			# 搜索压缩包
			mysql_tar=($(find ./ -regex  ".*mysql.*8.0.*.tar[\.(xg)z]*"))

			# mysql源码包下载路径
			mysqlDown=$mysql8_0Down

			break
			;;
		*)
			echo "输入错误，请输入"
	esac
done

# 如果本地不存在源码包，就会进行下载
if [[ -z $mysql_tar ]]
then
	wget -P $baseDir"/source/mysql" $mysqlDown
	mysql_tar=$(echo ${mysqlDown##*/})
	mysql_name=$(find $baseDir -name $mysql_tar)
	if [[ -z $mysql_tar ]]
	then
		echo "找不到mysql源码包"
		exit 1
	fi
else
	if [[ ${#mysql_tar[@]} -eq 1 ]]
	then
		mysql_name=${mysql_tar[0]}
	else
		echo "---------------------------"
		echo "---------------------------"
		# 选择mysql压缩包
		echo "选择需要解压的mysql包"
		select i in ${mysql_tar[@]}
		do
			mysql_name=$i
			break
		done
	fi
fi
# 创建安装目录
if [[ ! -d $installUrl ]]
then
   	mkdir $installUrl 
    if [[ $? != 0 ]]
    then
      echo "创建安装目录失败，检查权限"
      exit
    fi
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
bash $baseDir"/libs/deps.sh" "$baseDir" "$prefixDir"

# 创建mysql用户、用户组
groupadd mysql
useradd -r -s /sbin/nologin -g mysql mysql -d $installUrl

# 创建mysql数据目录
if [[ -d "$installUrl/data" ]]
then
  rm $installUrl/data -rf
else
  mkdir $installUrl/data
fi

# 创建日志目录
if [[ ! -d "$installUrl/logs" ]]
then
  mkdir "$installUrl/logs"
  touch "$installUrl/logs/error.log"
fi

# 配置环境变量
if [[ ! $(grep "PATH=\$PATH:$installUrl/bin" /etc/profile) ]]
then
  echo "PATH=\$PATH:$installUrl/bin" >> /etc/profile
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
	installInfo=$(./scripts/mysql_install_db --user=mysql --datadir=$installUrl/data)

elif  [[ $(echo $mysqlVer|awk '{print ($0/5.7)==1}') -eq 1 ]]
then
	# mysql 5.7版本
	installInfo=$(mysqld --initialize --user=mysql --basedir=$installUrl --datadir=$installUrl/data --pid-file=$installUrl/data/mysql.pid 2>&1 | grep "localhost")

elif  [[ $(echo $mysqlVer|awk '{print ($0/8.0)==1}') -eq 1 ]]
then
	# mysql 8.0版本
	installInfo=$(mysqld --initialize --user=mysql --basedir=$installUrl --datadir=$installUrl/data --pid-file=$installUrl/data/mysql.pid 2>&1 | grep "localhost")
else
	echo "mysql初始化失败"
	exit
fi

initPasswd=$(getPasswd)
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
