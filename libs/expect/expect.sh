#!/bin/bash


# 安装tcl程序函数

function installTcl(){
    
    # 安装Tcl语言扩展包
    # 搜索压缩包
    tclTarName=$(find $sourceDir -regex  ".*[Tt][Cc][Ll].*[Tt][Aa][Rr].[Gg][Zz]")
    if [[ -n $tclTarName ]]
    then
        # 解压源码包
        tar -zxvf $tclTarName -C $baseDir"/tar"
        # 进入编译目录
        tclTarDir=$(find $baseDir -regex '.*tar/[Tt][Cc][Ll][^/]*')
        cd "$tclTarDir/unix"
        # 预编译
        ./configure --prefix=$prefixDir"/tcl" --enable-shared
        # 安装
        make && make install
        if [[ $? -eq 0 ]]
        then
            echo "编译安装成功"
        else
            echo “编译失败”
            exit 1
        fi
        # 复制文件
        cd "$tclTarDir/unix"
        cp tclUnixPort.h ../generic/
    else
        echo "不存在tcl扩展语言源码包"
        exit 1
    fi
}

# 安装expect程序函数

function installExpect(){
    
    expectTarName=$(find $sourceDir -regex  ".*expect/[Ee][Xx][Pp][Ee][Cc][Tt].*[Tt][Aa][Rr].[Gg][Zz]")
    if [[ -n $expectTarName ]]
    then
        # 解压源码包
        tar -zxvf $expectTarName -C $baseDir"/tar"

        # 进入编译目录
        expectTarDir=$(find $baseDir -regex '.*tar/[Ee][Xx][Pp][Ee][Cc][Tt][^/]*')
        cd "$expectTarDir"
        # 预编译
        ./configure --prefix=$prefixDir"/expect" --with-tcl=$prefixDir"/tcl/lib" --with-tclinclude=$tclTarDir"/generic"
        # 安装
        make && make install
        if [[ $? -eq 0 ]]
        then
            echo "编译安装成功"
        else
            echo "编译失败"
            exit 1
        fi
        
        # 创建软链接
        ln -s $prefixDir"/tcl/bin/expect" $prefixDir"/expect/bin/expect"
    fi
}

# 根目录 
baseDir=$1

# 程序安装目录
prefixDir=$2


# 源码包目录
sourceDir="$baseDir/source/deps/expect"

# 创建tcl安装目录
if [[ ! -d $prefixDir"/tcl" ]]
then
mkdir $prefixDir"/tcl"
installTcl
else
while read -p "是否选择覆盖安装tcl，请输入Y/N？" isCover
do
    if [[ -n $(echo "yes,y" |grep -i "$isCover" ) ]]
    then
	installTcl
	break
    fi
    if [[ -n $(echo "NO,n" |grep -i "$isCover") ]]
    then
	break
    fi
done

fi  

# 安装 expect

# 创建expect目录
if [[ ! -d $prefixDir"/expect" ]]
then
mkdir $prefixDir"/expect"
installExpect
else
while read -p "是否选中覆盖安装expect，请输入Y/N？" isCover
do
    if [[ -n $(echo "yes,y"|grep -i "$isCover") ]]
    then
	installExpect
	break
    fi

    if [[ -n $(echo "NO,n"|grep -i "$isCover") ]]
    then
	break
    fi
done
fi

if [[ ! $(grep "PATH=\$PATH:$prefixDir/expect/bin" /etc/profile) ]]
then
    echo "PATH=\$PATH:$prefixDir/expect/bin" >> /etc/profile
    echo "export PATH" >> /etc/profile
fi
# 更改执行expect文件头部shell路径
extArr=$(find $baseDir -regex  ".**.ext")
for i in $extArr
do
    sed -i "1c\#!$prefixDir/expect/bin/expect" $i
done
source /etc/profile
