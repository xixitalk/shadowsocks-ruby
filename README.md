## 简介
功能：shadowsocks socks5 自动代理（autoproxy），本程序在树莓派raspbian系统上完整测试，其他平台未测试，请注意。  
PS：基于HTTP自动代理推荐[cow proxy](https://github.com/cyfdecyf/cow)

## 文件说明
### 程序运行必要文件：
* local.rb            shadowsocks原生文件，已经被大量修改
* encrypt.rb          shadowsocks原生文件
* merge_sort.rb       shadowsocks原生文件
* config.json         shadowsocks帐号配置文件
* checkHost.rb        提供检测网站是否能够直连函数
* connect             由connect.c编译的可执行文件，检测网站是否能够直连工具
* country_domain.txt  国家域名列表，domainRegex.rb使用
* domainRegex.rb      提供域名正则表达式
* block.json          不可直连网站列表
* direct.json         可直连网站列表
* connect.c           编译为可执行程序connect

### 其他文件说明
* server.rb           自动代理和server.rb无关，所以无修改，和shadowsocks原生的server.rb一样
* test.rb             测试文件
* transform.rb        测试文件

## 安装
### 安装eventmachine
安装ruby环境后使用`gem install eventmachine`安装eventmachine组件

### 编译connect.c
Linux/Unix/树莓派环境下使用`gcc connect.c -o connect`，其他系统请参看connect.c里文件头的编译说明。

## 运行
切换到local.rb所在的目录，使用`$ruby local.rb`来建立本地代理服务器（调试方式），最好使用`$ruby local.rb  > /dev/null 2>&1 &`来后台运行。

## 停止
尽量不要使用kill PID方式杀死运行的local.rb进程，原因是local.rb进程定时自动检测的不可连接网址会写入到block.json文件，如果写时被kill，结果会造成block.json文件内容丢失。direct.json文件存在同样的问题。如果block.json或者direct.json为空了，请手动写入`[]`到文件，不然local.rb运行会出错。

停止的方法：local.rb所在的目录创建一个emexit文件，local.rb进程在最近一次写入block.json或者direct.json后如果检测到存在emexit会自动退出，时间大约是600秒内。
