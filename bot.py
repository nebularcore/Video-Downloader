import os, asyncio, sys
try:
    from config import API_ID, API_HASH, BOT_TOKEN
except ImportError:
    print("Error: config.py not found! Run the install script first.")
    sys.exit(1)

from pyrogram import Client, filters
from pyrogram.types import InlineKeyboardMarkup, InlineKeyboardButton, CallbackQuery
from utils import get_video_info, download_video

app = Client("my_downloader", api_id=API_ID, api_hash=API_HASH, bot_token=BOT_TOKEN)

@app.on_message(filters.text & filters.private)
async def on_link(client, message):
    url = message.text
    if "http" not in url: return
    
    m = await message.reply("⏳ در حال آنالیز لینک...")
    try:
        formats, title = await asyncio.to_thread(get_video_info, url)
        if not formats:
            return await m.edit("❌ کیفیت مناسبی یافت نشد.")
            
        buttons = []
        seen = set()
        for f in formats:
            if f['res'] not in seen:
                buttons.append([InlineKeyboardButton(f"Download {f['res']}", callback_data=f"{f['id']}|{url}")])
                seen.add(f['res'])
        
        await m.edit(f"🎬 **{title}**\nکیفیت مورد نظر را انتخاب کنید:", reply_markup=InlineKeyboardMarkup(buttons))
    except Exception as e:
        await m.edit(f"❌ خطایی رخ داد: {e}")

@app.on_callback_query()
async def on_click(client, callback_query: CallbackQuery):
    f_id, url = callback_query.data.split("|", 1)
    file_path = f"downloads/{callback_query.from_user.id}.mp4"
    
    await callback_query.message.edit("📥 در حال دانلود روی سرور...")
    try:
        if not os.path.exists("downloads"): os.makedirs("downloads")
        await asyncio.to_thread(download_video, url, f_id, file_path)
        await callback_query.message.edit("📤 در حال آپلود در تلگرام...")
        
        await client.send_video(
            chat_id=callback_query.message.chat.id,
            video=file_path,
            supports_streaming=True,
            caption="✅ تقدیم به شما"
        )
    except Exception as e:
        await callback_query.message.reply(f"❌ خطای دانلود: {e}")
    finally:
        if os.path.exists(file_path): os.remove(file_path)
        await callback_query.message.delete()

if __name__ == "__main__":
    app.run()
  
