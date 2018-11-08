---
elasticsearch.md - 测试v500对elasticsearch的兼容性及其基本功能
Hardware platform: D05，D06
Software Platform: CentOS Ubuntu Debian Fedora openSUSE
Author: Liu Caili <meili760628705@163.com>  
Date: 2017-11-09 15:31
Categories: Estuary Documents  
Remark:
---


# Dependency
```
    (1)已安装jdk

	1)
	centos/fedora: yum install java-1.8.0-openjdk
	opensuse: zypper install java-1_8_0-openjdk
	ubuntu/debian: apt install openjdk-8-jdk

	2)java -version

    (2)添加estuary软件包源(#如有,则不需添加)

```
#Test
```
    (1)安装elasticsearch

	wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.6.3.tar.gz
       
    (2)解压elasticsearch到/home目录下

	tar -zxf elasticsearch-5.6.3.tar.gz -C /home
       
    (3)运行elasticsearch

	a.Elasticsearch要求不能使用超级用户root运行，建立一个testuser账号

	    adduser testuser

	    passwd testuser

	b.给testuser用户elasticsearch目录的授权

	    chown -R testuser /home/elasticsearch-5.6.3/

	c.切换至elasticsearch目录，并以testuser用户运行

	    cd /home/elasticsearch-5.6.3/

	    su testuser
	
	d.运行elasticsearch 

	    ./bin/elasticsearch   # 如果不报错说明运行成功


    (4)新开一个终端,查看elasticsearch是否启动成功

	    curl 'http://localhost:9200/?pretty' 

    (5)添加一个test索引(可理解为数据库)

	    curl -XPUT 'http://localhost:9200/test?pretty'

    (6)创建一个名叫 article 的类型（即表名）

	    curl -XPUT 'http://localhost:9200/test/_mapping/article?pretty' -d '{
  	      "properties": {
  	          "id": {
  	              "type":      "integer",
  	              "index":     "not_analyzed"
  	          },
  	          "subject": {
  	              "type":      "string",
  	              "analyzer":  "standard"
  	          },
  	          "content": {
  	              "type":      "string",
  	              "analyzer":  "standard"
  	          },
  	          "author": {
  	              "type":      "string",
  	              "index":     "not_analyzed"
  	          }
	    }
    }'

    (7)创建一条数据(文档)

	    curl -X PUT 'http://localhost:9200/test/article/1?pretty' -d '{"employee":"emp32"}'


    (8)查看指定文档

	    curl -X XGET 'http://localhost:9200/test/article/1?pretty'


    (9)修改或更新文档

	    curl -XPOST 'http://localhost:9200/test/article/1/_update?pretty' -d '
	    {
    		    "doc" : {
       			 "content" : "测试测试"
   		 }
	}'

    (10)查看所有文档

	    curl -XGET 'http://localhost:9200/test/article/_search?pretty'
	
    (11)删除文档

	    curl -XDELETE 'http://localhost:9200/test/article/1?pretty'


    (12)elasticsearch指定ip地址

	    切换到root用户, 编辑文件/config/elasticsearch.yml

	    a.找到network.host，去除#号，修改为 network.host: 192.168.1.130(单板IP)

	    b.找到http.port, 去除#号, 修改为 http.port: 9200

	    c.关闭防火墙
		
		centos:
		1)systemctl stop firewall;

                2)systemctl disable firewall

		debian:
		1)apt-get install ufw

		2)ufw disable

            d.切换到testuser用户,启动elasticsearch
        
    (13)打开浏览器,输入 http://192.168.1.130:9200,查看信息
       
    (14)关闭elasticsearch

	    kill -9 进程号

	    或者

	    curl -X POST http://localhost:9200/_cluster/nodes/_shutdown
       
    (15)卸载elasticsearch	

	    rm -rf  elasticsearch-5.6.3

```
  
#Result
```

      测试上述步骤是否全部通过，若是，则pass；若不是，则fail
```
