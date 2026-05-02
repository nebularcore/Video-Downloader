#!/bin/bash

# تعریف رنگ‌ها برای زیبایی منو
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
SERVICE_NAME="vidbot"

# تابع نصب کامل
install_bot() {
    echo -e "${YELLOW}--- در حال نصب و کانفیگ اولیه ---${NC}"
    sudo apt-get update -y
    sudo apt-get install -y python3 python3-pip python3-venv ffmpeg git

    reconfigure_bot

    echo -e "${YELLOW}Setting up Python Environment...${NC}"
    python3 -m venv "$DIR/venv"
    source "$DIR/venv/bin/activate"
    pip install -r "$DIR/requirements.txt"
    mkdir -p "$DIR/downloads"

    echo -e "${YELLOW}Creating Background Service...${NC}"
    USER_NAME=$(whoami)
    sudo bash -c "cat <<EOF > /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=Telegram Video Downloader Bot
After=network.target

[Service]
User=$USER_NAME
WorkingDirectory=$DIR
ExecStart=$DIR/venv/bin/python $DIR/bot.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF"

    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_NAME
    sudo systemctl start $SERVICE_NAME
    echo -e "${GREEN}✅ نصب با موفقیت انجام شد و ربات روشن است!${NC}"
}

# تابع تغییر مقادیر
reconfigure_bot() {
    echo -e "${CYAN}--- تنظیم توکن‌ها ---${NC}"
    read -p "Enter API_ID: " INPUT_API_ID
    read -p "Enter API_HASH: " INPUT_API_HASH
    read -p "Enter BOT_TOKEN: " INPUT_BOT_TOKEN

    cat <<EOF > "$DIR/config.py"
API_ID = $INPUT_API_ID
API_HASH = "$INPUT_API_HASH"
BOT_TOKEN = "$INPUT_BOT_TOKEN"
EOF
    echo -e "${GREEN}✅ مقادیر جدید ذخیره شدند.${NC}"
    if systemctl is-active --quiet $SERVICE_NAME; then
        sudo systemctl restart $SERVICE_NAME
        echo -e "${GREEN}🔄 ربات با توکن‌های جدید ری‌استارت شد.${NC}"
    fi
}

# تابع آپدیت سورس کد و yt-dlp
update_bot() {
    echo -e "${YELLOW}--- در حال دریافت آخرین آپدیت‌ها ---${NC}"
    git pull origin main
    source "$DIR/venv/bin/activate"
    pip install -U yt-dlp  # آپدیت اجباری هسته دانلودر
    pip install -r "$DIR/requirements.txt"
    sudo systemctl restart $SERVICE_NAME
    echo -e "${GREEN}✅ ربات و ابزار دانلود آپدیت شدند!${NC}"
}

# تابع مشاهده لاگ‌ها
show_logs() {
    echo -e "${CYAN}--- در حال نمایش لاگ‌های زنده (برای خروج CTRL+C را بزنید) ---${NC}"
    sudo journalctl -u $SERVICE_NAME -f -n 50
}

# تابع حذف کامل
uninstall_bot() {
    echo -e "${RED}--- آیا از حذف کامل ربات و سورس‌ها مطمئن هستید؟ (y/n) ---${NC}"
    read -p "> " CONFIRM
    if [ "$CONFIRM" = "y" ]; then
        sudo systemctl stop $SERVICE_NAME
        sudo systemctl disable $SERVICE_NAME
        sudo rm /etc/systemd/system/$SERVICE_NAME.service
        sudo systemctl daemon-reload
        rm -rf "$DIR/venv" "$DIR/downloads" "$DIR/config.py"
        echo -e "${GREEN}✅ ربات با موفقیت از سیستم پاک شد. (پوشه سورس‌ها حفظ شده است)${NC}"
    else
        echo -e "${YELLOW}عملیات حذف لغو شد.${NC}"
    fi
}

# نمایش منوی اصلی
show_menu() {
    clear
    echo -e "${CYAN}=======================================${NC}"
    echo -e "${GREEN}   🤖 مدیر ربات دانلودر ویدیو ${NC}"
    echo -e "${CYAN}=======================================${NC}"
    echo -e "1) 🚀 نصب و راه‌اندازی اولیه"
    echo -e "2) 🔄 آپدیت سورس کد و yt-dlp"
    echo -e "3) ⚙️ تنظیم مجدد توکن‌ها"
    echo -e "4) 📜 مشاهده لاگ‌ها و ارورها"
    echo -e "5) ♻️ ری‌استارت سرویس ربات"
    echo -e "6) 🗑 حذف ربات از سرور"
    echo -e "0) ❌ خروج"
    echo -e "${CYAN}=======================================${NC}"
    read -p "یک گزینه را انتخاب کنید [0-6]: " choice

    case $choice in
        1) install_bot ;;
        2) update_bot ;;
        3) reconfigure_bot ;;
        4) show_logs ;;
        5) sudo systemctl restart $SERVICE_NAME && echo -e "${GREEN}✅ ربات ری‌استارت شد.${NC}" ;;
        6) uninstall_bot ;;
        0) exit 0 ;;
        *) echo -e "${RED}❌ گزینه نامعتبر!${NC}" ;;
    esac
    
    echo ""
    read -p "برای بازگشت به منو اینتر بزنید..."
    show_menu
}

# اجرای حلقه منو
show_menu
