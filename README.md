EMC testnet cuda 测试网挖矿项目

该项目为测试项目 请避免金钱交易。



加入tg群。 第一时间获取最新版本更新
https://t.me/+h_yk1Pa3GlQ0NDZl


EMC链上卡TX不是我的问题。 链的问题 。尽量优化了

更新内容：
更改提交tx为异步,增加自定义池. 优化矿池tx提交



EMP挖矿项目

矿池合约地址 0x992D0456120978dD9626aEBa765CAf579dA221dC

EMP 代币地址 0x8d575AdcDbfa2068F7e904E9E222bF47B8375614

EMP代币 上限100亿 创建时已经全部打入合约 无法取出 只能靠挖 大家加油 

SWAP地址

EMP/EMC  swap 池子。 请为EMP/EMC添加流动性 当EMP足够多的时候  我会购买

https://espoir1989.github.io/EMC-Swap/#/swap

加入token list

https://raw.githubusercontent.com/Souging/emc_gpu_pool/main/token.json




请在钱包内添加代币地址

目前锄头只支持linux 请自行wsl或者原生ubuntu

先克隆仓库

git clone https://mirror.ghproxy.com/https://github.com/Souging/emc_gpu_pool.git

然后 cd emc_gpu_pool

给予运行权限

chmod +x guaguagua_linux && chmod +x emc_cuda_pool

2.命令运行



用的是ubuntu 22.04编译的  

不推荐！！！！
如果你低于这个版本 需要更新glibc

echo deb http://mirrors.aliyun.com/ubuntu jammy main >> /etc/apt/sources.list && apt update && apt install libc6 -y 

推荐： ubuntu 22.04  + cuda 12.4


矿池不断优化中。 请使用循环命令来保持程序一直运行


 while true; do ./emc_cuda_pool -miner 0x1234567891234578912 -p 1; sleep 1; done


./emc_cuda_pool -miner 0x1234567891234578912 -p 1     替换你的钱包地址 和矿池代号

目前 -p 1 为
欧洲俄罗斯矿池地址为:69.165.74.244

目前 -p 2 为
美国矿池地址为:38.45.72.116



其他待定

自行选择最优线路


目前仅支持单路显卡

收益比例为 每个tx 0.05 EMC + 0.05EMP

已测
4090  一秒N个tx
3070 大概1-2秒一个TX~ 
2060s  3-4秒一个tx~

自由发挥~
