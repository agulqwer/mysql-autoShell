#!/bin/bash

# 获取mysql初始密码函数

function getPasswd(){
    if [[ -n $installInfo ]]
    then
        passwd=${installInfo#*localhost:}
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

}

# 赋予 sh,ext文件执行权限
shExt=$(find ./ -regextype posix-extended -regex ".*.(sh|ext)$");
for i in $shExt
do
	chmod u+x $i
done

# 获取压缩包的路径
baseDir=$(pwd)
echo "输入安装路径"
read prefixDir
installUrl=$prefixDir"/mysql"
echo "设置mysql密码（至少8位以上字母和数字组合）"
shopt -s extglob
while read setPasswd
do
    if [[ -n $( echo "$setPasswd"|grep -P "^(?=.*[0-9])(?=.*[a-zA-Z])(.{8,})$") ]]
    then
        break
    else
        echo "密码必须包含8位以上的字母和数字"
    fi
done
mysql_tar=$(find $baseDir -regex ".*/source/mysql/mysql.*.tar.gz")

# 如果本地不存在源码包，就会进行下载
while [[ -z $mysql_tar ]]
then
	wget -p ./source/mysql https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.30-linux-glibc2.12-x86_64.tar.gz
	mysql_tar=$(find $baseDir -regex ".*/source/mysql/mysql.*.tar.gz")
fi

# 选择mysql压缩包
echo "选择需要解压的mysql包"
select name_tar in $mysql_tar
do
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
  tar -zxvf $name_tar -C $installUrl --strip-components 1
  if [[ $? == 0 ]]
  then
    echo "解压成功"
    break
  else
    echo "解压失败"
    exit
  fi
done

# 检查并安装依赖
./libs/deps.sh "$baseDir" "$prefixDir"

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
installInfo=$(mysqld --initialize --user=mysql --basedir=$installUrl --datadir=$installUrl/data --pid-file=$installUrl/data/mysql.pid 2>&1 | grep "localhost")
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
    expect "$baseDir/libs/mysql/mysql.ext" "$initPasswd" "$setPasswd" 
fi
