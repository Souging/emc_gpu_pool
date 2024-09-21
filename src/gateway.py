import logging
import threading
import queue
import time
from logging import StreamHandler
from colorama import Fore, Back, Style, init
from web3 import Web3, HTTPProvider
from flask import Flask, request, jsonify

# 初始化 colorama
init(autoreset=True)

# 配置日志
class ColoredFormatter(logging.Formatter):
    def __init__(self):
        super().__init__(fmt='%(asctime)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')

    def format(self, record):
        log_fmt = {
            logging.DEBUG: Fore.CYAN + '%(asctime)s - %(levelname)s - %(message)s' + Style.RESET_ALL,
            logging.INFO: Fore.GREEN + '%(asctime)s - %(levelname)s - %(message)s' + Style.RESET_ALL,
            logging.WARNING: Fore.YELLOW + '%(asctime)s - %(levelname)s - %(message)s' + Style.RESET_ALL,
            logging.ERROR: Fore.RED + '%(asctime)s - %(levelname)s - %(message)s' + Style.RESET_ALL,
            logging.CRITICAL: Fore.RED + Back.WHITE + '%(asctime)s - %(levelname)s - %(message)s' + Style.RESET_ALL
        }
        formatter = logging.Formatter(log_fmt.get(record.levelno, '%(asctime)s - %(levelname)s - %(message)s'))
        return formatter.format(record)

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# 控制台处理器
console_handler = StreamHandler()
console_handler.setFormatter(ColoredFormatter())
logger.addHandler(console_handler)

# 合约详情
contract_address = '0xBb9EB992D0eC2A446F0B67519daCf4Aa59579AEe'  # emc的合约地址
contract_abi = [
    {
        "constant": False,
        "inputs": [
            {"name": "to", "type": "address"},
            {"name": "_difficulty", "type": "bytes32"}
        ],
        "name": "claim",
        "outputs": [],
        "payable": True,
        "stateMutability": "payable",
        "type": "function"
    },
    # 添加其他ABI部分
]

# 创建Web3实例
web3 = Web3(HTTPProvider('https://rpc1-testnet.emc.network/'))

# 检查连接
if not web3.isConnected():
    logger.error("无法连接到以太坊节点")
    raise Exception("无法连接到以太坊节点")

# 创建合约实例
contract = web3.eth.contract(address=contract_address, abi=contract_abi)

# 账户详情
from_address = '钱包地址'  # 替换为你的钱包地址
private_key = '私钥'  # 替换为你的私钥

# 初始化nonce
nonce_lock = threading.Lock()
current_nonce = web3.eth.getTransactionCount(from_address, 'pending')

# 初始化交易队列
transaction_queue = queue.Queue()

def get_next_nonce():
    """以线程安全的方式获取下一个可用的nonce。"""
    global current_nonce
    with nonce_lock:
        nonce = current_nonce
        current_nonce += 1
    return nonce

def update_nonce_from_chain():
    """从链上获取最新的nonce并更新。"""
    global current_nonce
    with nonce_lock:
        current_nonce = web3.eth.getTransactionCount(from_address, 'pending')
    logger.info(f"从链上更新nonce: {current_nonce}")

def submit_transaction(difficulty):
    """提交EIP-1559类型2交易并返回交易哈希。"""
    try:
        to_address = '钱包地址'  # 替换为接收地址

        latest_block = web3.eth.get_block('latest')
        base_fee_per_gas = latest_block['baseFeePerGas']

        # 设置gas费用
        max_priority_fee_per_gas = Web3.toWei('10', 'gwei')
        max_fee_per_gas = Web3.toWei('500', 'gwei')

        nonce = get_next_nonce()

        # 构建EIP-1559类型2交易
        transaction = contract.functions.claim(to_address, difficulty).buildTransaction({
            'from': from_address,
            'value': Web3.toWei(0, 'ether'),
            'gas': 120000,
            'maxFeePerGas': max_fee_per_gas,
            'maxPriorityFeePerGas': max_priority_fee_per_gas,
            'nonce': nonce,
            'type': 2
        })

        logger.debug(f"构建的交易: {transaction}")

        # 签署交易
        signed_txn = web3.eth.account.sign_transaction(transaction, private_key=private_key)
        logger.debug(f"签署的交易: {signed_txn.rawTransaction.hex()}")

        # 发送交易
        txn_hash = web3.eth.sendRawTransaction(signed_txn.rawTransaction)
        logger.info(f"交易已发送，交易哈希: {txn_hash.hex()}")

        # 将交易哈希添加到队列
        transaction_queue.put(txn_hash.hex())

        return txn_hash.hex()
    except Exception as e:
        logger.error(f"提交交易时出错: {e}")
        if "nonce" in str(e).lower():
            logger.info("检测到nonce错误，重新从链上获取nonce")
            update_nonce_from_chain()
        return None

app = Flask(__name__)

@app.route('/submit', methods=['POST'])
def submit():
    data = request.json
    solution = data.get('solution')

    if not solution:
        return jsonify({"error": "未提供解决方案"}), 400
    if not solution.startswith('0x'):
        solution = '0x' + solution

    # 立即提交交易
    txn_hash = submit_transaction(solution)
    if txn_hash:
        return jsonify({"message": "交易已发送", "tx_hash": txn_hash})
    else:
        return jsonify({"error": "发送交易失败"}), 500

def monitor_queue_and_clear():
    """监控队列大小并每10分钟清理队列。"""
    while True:
        # 输出当前队列大小
        logger.info(f"当前队列大小: {transaction_queue.qsize()}")

        # 清理队列
        with transaction_queue.mutex:
            transaction_queue.queue.clear()
        logger.info("队列已清理")

        # 每10分钟执行一次
        time.sleep(600)

if __name__ == '__main__':
    # 启动监控线程
    monitor_thread = threading.Thread(target=monitor_queue_and_clear, daemon=True)
    monitor_thread.start()

    # 启动Flask应用
    app.run(host='0.0.0.0', port=7666)
