cuda源码  会用的自己用 不会用的有空再写简介
先修改main.cu内的地址 难度 之类的参数 

然后修改run.go 中的网关参数

1.先运行网关

网关必须带上重启命令
while true; do timeout 60 python3 gateway.py; sleep 1; done

2. 直接用make命令编译cu


3.直接运行 go run run.go  来调用cuda回显


