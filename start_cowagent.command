#!/bin/bash

# 切换到脚本所在的目录（即项目目录）
cd "$(dirname "$0")"
CURRENT_DIR=$(pwd)

echo "=================================================="
echo "正在检测官方新版本并自动更新..."
echo "=================================================="
# 获取上游仓库最新代码
git fetch upstream

# 尝试自动合并官方最新代码
if ! git merge upstream/main; then
    echo "🚨 警告：检测到代码冲突！"
    echo "自动更新已被打断。为了保护你的本地配置，合并操作已撤销。"
    echo "👉 请回到 AI 对话框，将此信息告诉 AI 助手，让它帮你解决冲突。"
    git merge --abort
    
    echo ""
    read -p "按回车键将使用【旧版本】继续启动，或按 Ctrl+C 退出..."
else
    echo "✅ 代码已是最新，或更新已成功自动合入！"
fi

echo "正在清理旧进程..."
# 杀死之前的 app.py 和相关进程
pkill -f "python.*app.py"
pkill -f "tail.*nohup.out"
pkill -f "cow start"

echo "正在检查运行环境..."

# 检查虚拟环境是否存在且路径是否正确
if [ -d "venv" ]; then
    VENV_PATH=$(grep "export VIRTUAL_ENV=" venv/bin/activate | cut -d "=" -f 2 | tr -d "'" | tr -d '"')
    if [ "$VENV_PATH" != "$CURRENT_DIR/venv" ]; then
        echo "=================================================="
        echo "检测到项目路径发生变化，旧的虚拟环境失效，正在修复..."
        echo "当前目录: $CURRENT_DIR"
        echo "旧的环境路径: $VENV_PATH"
        echo "=================================================="
        # 清除缓存，防止加载旧路径代码
        find . -name "*.pyc" -delete
        find . -name "__pycache__" -delete
        
        chmod -R u+w venv
        rm -rf venv
        python3 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip
        pip install -r requirements.txt
        pip install -e .
    else
        source venv/bin/activate
    fi
else
    echo "=================================================="
    echo "未检测到虚拟环境，正在创建..."
    echo "=================================================="
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    pip install -e .
fi

echo "=================================================="
echo "启动 CowAgent (后台运行)..."
echo "=================================================="

# 直接在后台启动 python app.py
nohup python app.py > run.log 2>&1 &

echo "等待服务启动..."
sleep 2

echo "正在打开浏览器..."
open http://localhost:9899/chat

echo "=================================================="
echo "启动完成！该窗口将自动关闭。"
echo "=================================================="

sleep 1

# 自动关闭当前终端窗口 (macOS)
osascript -e 'tell application "Terminal" to close front window'
