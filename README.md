# mysql-autoShell
**linux shell程序，一键自动化安装mysql**

- **目录结构**

  .  
  ├── libs  
  │   ├── deps.sh --------------------------------- 安装依赖文件  
  │   ├── expect  
  │   │   └── expect.sh --------------------------- 安装expect文件  
  │   └── mysql  
  │       ├── my.cnf------------------------------- mysql配置文件  
  │       ├── mysqld.service ---------------------- mysql systemctl服务管理文件  
  │       └── mysql.ext --------------------------- mysql 自动化交互文件  
  ├── mysql.sh ------------------------------------ mysql 安装程序  
  ├── README.md ----------------------------------- 说明文档  
  ├── source -------------------------------------- 存放源码包路径  
  │   ├── deps ------------------------------------ 依赖目录  
  │   │   └── expect  
  │   │       ├── expect5.45.3.tar.gz ------------- 自动化交互套件  
  │   │       └── TCl8.6.10-src.tar.gz ------------ tcl 脚本语言包  
  │   └── mysql ----------------------------------- 存放msyql二进制源码包目录  
  └── tar ----------------------------------------- 源码包解压临时目录  

- **系统环境**

  - linux 版本：centos 7
  - mysql 版本：5.7

- **安装**

  - 进入目录

    ```
    cd mysql-autoShell
    ```

  - 赋予权限

    ```
    chmod u+x mysql.sh
    ```

  - 执行

    ```
    ./mysql.sh
    ```

- **git 自动安装**

  ```
  git clone https://github.com/agulqwer/mysql-autoShell.git && cd mysql-autoShell && bash mysql.sh
  ```

  
