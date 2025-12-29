import discord
from discord import app_commands
from discord.ext import commands
import os
import asyncio
from groq import Groq
import requests
import random
import math
import httpx
import logging
from pydub import AudioSegment
from flask import Flask
from threading import Thread

# --- Flask (Koyebヘルスチェック回避用) ---
app = Flask('')
log = logging.getLogger('werkzeug')
log.setLevel(logging.WARNING)

@app.route('/')
def home():
    return "I'm alive"

def run_flask():
    app.run(host='0.0.0.0', port=8000)

def keep_alive():
    t = Thread(target=run_flask)
    t.start()

# --- 設定 ---
DISCORD_TOKEN = os.getenv('DISCORD_TOKEN')
GROQ_API_KEY = os.getenv('GROQ_API_KEY')
VOICEVOX_URL = 'http://127.0.0.1:50021'
HANAMARU_ID = 69 

client = Groq(api_key=GROQ_API_KEY)

intents = discord.Intents.default()
intents.message_content = True

class MyBot(commands.Bot):
    def __init__(self):
        super().__init__(command_prefix="!", intents=intents)

    async def setup_hook(self):
        await self.tree.sync()
        print(f"Synced slash commands for {self.user}")

bot = MyBot()

# --- 共通の対話ロジック ---
async def process_voice_interaction(interaction: discord.Interaction, user_text: str):
    step = "開始"
    print(f"--- [DEBUG] {step}: ユーザー入力 = {user_text}")
    
    # 応答用メッセージの初期化
    user_name = interaction.user.display_name
    display_message = ""

    try:
        # 1. Groq AIで返答生成
        step = "Groq AI呼び出し"
        chat_completion = client.chat.completions.create(
            messages=[
                {"role": "system", "content": "アニメ「鬼滅の刃」に出てくる継国縁壱のような、極めて穏やかで、謙虚かつ淡々とした口調にしてください。しかし敬語は使わないでください。"},
                {"role": "user", "content": user_text}
            ],
            model="llama-3.1-8b-instant",
        )
        response_text = chat_completion.choices[0].message.content
        print(f"--- [DEBUG] AI返答成功: {response_text}")

        combined_text = f"{user_name}「{user_text}」……ネアーノ「{response_text}」"
        display_message = f"**{user_name}**: {user_text}\n**ネアーノ**: {response_text}"

        # 2. VOICEVOXでの音声合成
        voice_success = False
        
        step = "VOICEVOXリクエスト開始"
        async with httpx.AsyncClient(timeout=httpx.Timeout(60.0)) as httpx_client:
            # クエリ作成
            step = "VOICEVOXクエリ作成"
            res1 = await httpx_client.post(
                f'{VOICEVOX_URL}/audio_query', 
                params={'text': combined_text, 'speaker': HANAMARU_ID}
            )
            res1.raise_for_status()
            query_data = res1.json()

            # 音声合成
            step = "VOICEVOX音声合成"
            res2 = await httpx_client.post(
                f'{VOICEVOX_URL}/synthesis',
                params={'speaker': HANAMARU_ID},
                json=query_data
            )
            res2.raise_for_status()
            
            step = "ファイル保存"
            with open("response.wav", "wb") as f:
                f.write(res2.content)
            print("--- [DEBUG] 音声ファイル保存完了")

        # 3. 再生処理
        step = "ボイスクライアント確認"
        voice_client = interaction.guild.voice_client

        if voice_client:
            step = "VC接続待ち"
            count = 0
            # 接続されるまで最大6秒待機
            while not voice_client.is_connected() and count < 60:
                await asyncio.sleep(0.1)
                count += 1
            
            if voice_client.is_connected():
                step = "再生準備"
                await asyncio.sleep(1.0)
                ffmpeg_options = {'options': '-vn'}
                if voice_client.is_playing():
                    voice_client.stop()
                
                step = "再生実行"
                voice_client.play(discord.FFmpegPCMAudio("response.wav", **ffmpeg_options))
                print("--- [DEBUG] 再生コマンド送信完了")
                voice_success = True
            else:
                print("--- [DEBUG] VC接続タイムアウト")
        else:
            print("--- [DEBUG] voice_clientが見つからない")

        # 4. メッセージ送信
        if voice_success:
            await interaction.followup.send(display_message)
        else:
            await interaction.followup.send(f"（声の準備が間に合わなかった。済まない。）\n{display_message}")

    except Exception as e:
        error_msg = f"!!! [CRITICAL ERROR] 段階: {step} / 内容: {str(e)}"
        print(error_msg)
        # 最低限の返答を返す
        if not interaction.responses.is_done():
             await interaction.followup.send(f"（不具合が生じた。段階: {step}）\n{display_message if display_message else ''}")
        else:
             print("Interaction already finished, could not send error message to Discord.")

# --- スラッシュコマンド定義 ---

# 5. ヘルプコマンド
@bot.tree.command(name="help", description="このBotの使い方とコマンド一覧を表示する")
async def help_command(interaction: discord.Interaction):
    embed = discord.Embed(
        title="ネアーノBot 使い方ガイド",
        description="私はAI（Groq）とVOICEVOXを搭載した者だ。",
        color=discord.Color.pink()
    )
    embed.add_field(name="/start", value="ボイスチャンネルに接続する。声で会話したい場合はこちらを使おう。", inline=False)
    embed.add_field(name="/talk [メッセージ]", value="ネアーノ（CV:満別花丸）と会話する。VCに接続している場合は声で会話する。", inline=False)
    embed.add_field(name="/stop", value="VCから切断する。", inline=False)
    embed.add_field(name="/kazu", value="より小さい確率で大きい数が出る。特に大きい数が出ると何かあるかも？", inline=False)
    embed.add_field(name="/omikuji", value="伏見稲荷大社風おみくじを引く。", inline=False)
    embed.add_field(name="/help", value="このメニューを表示する。", inline=False)

    embed.set_footer(text="使い方に迷ったときは、いつでもこの案内を見るといい。")
    
    await interaction.response.send_message(embed=embed, ephemeral=True)

@bot.tree.command(name="start", description="VCに接続する")
async def start(interaction: discord.Interaction):
    if interaction.user.voice:
        # 先に応答を返し、タイムアウトを防ぐ
        await interaction.response.send_message("これより接続を試みる。少々待っていてくれ。")
        
        channel = interaction.user.voice.channel
        try:
            # timeoutを60秒に延長し、self_deaf(スピーカーミュート)を有効にして負荷を軽減する
            await channel.connect(timeout=60.0, self_deaf=True)
            await interaction.edit_original_response(content=f"{channel.name} に接続した。私に用があれば、いつでも話しかけてほしい。")
        except Exception as e:
            print(f"Connect Error: {e}")
            await interaction.edit_original_response(content="済まない、接続が時間切れとなってしまった。もう一度試してみてくれないか。")
    else:
        await interaction.response.send_message("まずはボイスチャンネルに入ってくれないだろうか。")

@bot.tree.command(name="stop", description="VCから切断する")
async def stop(interaction: discord.Interaction):
    if interaction.guild.voice_client:
        await interaction.guild.voice_client.disconnect()
        await interaction.response.send_message("承知した。また会える日を楽しみにしている。")
    else:
        await interaction.response.send_message("今はどこにも繋がっていないようだ。")

@bot.tree.command(name="talk", description="ネアーノと会話する")
@app_commands.describe(message="話したい内容を入力してね")
async def talk(interaction: discord.Interaction, message: str):
    await interaction.response.defer()
    await process_voice_interaction(interaction, message)

# 6. 伏見稲荷大社風・本格おみくじコマンド (AIアドバイス修正版)
@bot.tree.command(name="omikuji", description="伏見稲荷大社の17種類のおみくじを引く")
async def omikuji(interaction: discord.Interaction):
    # 応答を保留にする
    await interaction.response.defer()

    fortunes = [
        "⒈大大吉", "⒉大吉", "⒊向大吉（むこうだいきち）", "⒋末大吉",
        "⒌吉凶未分末大吉（よしあし いまだ わからず すえだいきち）", "⒍吉", "⒎中吉", "⒏小吉",
        "⒐後吉", "⒑末吉", "⒒吉凶不分末吉（きちきょう わかたず すえきち）",
        "⒓吉凶相交末吉（きちきょう あいまじわり すえきち）", "⒔吉凶相半（きちきょう あいなかばす）",
        "⒕吉凶相央（きちきょう あいなかばす）", "⒖小凶後吉（しょうきょうのちきち）",
        "⒗凶後吉（きょうのちきち）", "⒘凶後大吉（きょうのちだいきち）"
    ]
    
    weights = [2, 8, 5, 5, 3, 12, 10, 10, 8, 10, 5, 5, 4, 4, 3, 4, 2]
    result = random.choices(fortunes, weights=weights, k=1)[0]

    # AIへの指示を「おみくじの本文」風に変更
    prompt_content = (
        f"おみくじで「{result}」が出た人への『御神託（お告げ）』を書いてください。"
        f"話す口調は、アニメ「鬼滅の刃」に出てくる継国縁壱のような、極めて穏やかで、謙虚かつ淡々とした口調でお願いします。"
        f"丁寧語などの敬語を絶対に使わないでください。"
        f"おみくじの紙に書いてあるような『教え』を、必ず2文で書いてください。"
        f"『教え』は必ず抽象的にならないように書いてください。"
        f"「AI」という言葉は絶対に使わないでください。"
    )

    try:
        chat_completion = client.chat.completions.create(
            messages=[
                {"role": "system", "content": "あなたは神社に仕えている男性です。"},
                {"role": "user", "content": prompt_content}
            ],
            model="llama-3.3-70b-versatile",
        )
        ai_advice = chat_completion.choices[0].message.content
    except Exception as e:
        print(f"Groq API Error: {e}")
        ai_advice = f"神様の導きが途切れてしまったようだ。だが、この「{result}」という運命を静かに受け止めてほしい。"

    embed = discord.Embed(
        title="🦊 伏見稲荷大社・奉納おみくじ 🦊",
        description=f"あなたの運勢をお出しした。\n\n**【 運 勢 】**\n# {result}",
        color=discord.Color.red()
    )
    # フィールド名を「御神託」や「教え」にする
    embed.add_field(name="御神託", value=ai_advice)
    embed.set_footer(text="伏見稲荷の伝統的な17種類。この教えを大切にするのだぞ。")
    
    await interaction.followup.send(embed=embed)

# 7. より低い確率で大きい数が出るコマンド
@bot.tree.command(name="kazu", description="より低い確率で大きい数が出る（非常に大きい数が出ると何かあるかもしれない...）")
async def kazu(interaction: discord.Interaction):
    n = 0
    # 継続確率 95%
    while random.random() < 0.95:
        n += 1

    base_value = 2 ** n
    variation_percent = random.randint(-100, 100)
    total_result = int(base_value + (base_value * (variation_percent / 100)))

    # 確率計算
    prob = 0.95 ** n
    f_num = f"{total_result:,}"
    
    # 演出の分岐：1/10,000以下はすべて最大サイズ（#）
    if prob <= 1/1000000:
        display = f"# {f_num}"
        comment = f"信じがたい。これほどの巡り合わせに出会うとは。稀有な運命を持っているのだな。これは宝くじ2等レベルの確率に相当する。（💰1/1,000,000以下）"
    elif prob <= 1/100000:
        display = f"# {f_num}"
        comment = f"そなたは、一体どれほどの道を歩んできたのだ。その歩みが、この奇跡を引き寄せたのかもしれぬ。これは手術の全身麻酔事故で死亡する確率に相当する。（☠️1/100,000以下）"
    elif prob <= 1/10000:
        display = f"# {f_num}"
        comment = f"驚いた。これほどまでの強運を目の当たりにすることは、滅多にないことだ。これは一生涯に落雷に遭う確率に相当する。（⚡1/10,000以下）"
    elif prob <= 1/1000:
        display = f"## {f_num}"
        comment = f"見事だ。そなたの持つ力が、この結果を導いたのだろう。これは今日家を出たら事故に遭う確率に相当する。（💥1/1,000以下）"
    elif prob <= 1/100:
        display = f"**{f_num}**"
        comment = f"百に一つの巡り合わせか。良い兆しだ。（🔥1/100以下）"
    else:
        display = f_num
        comment = ""

    await interaction.response.send_message(f"{display}\n{comment}")

# --- 起動 ---
if __name__ == "__main__":
    # Flaskを先に確実に起動する
    keep_alive()
    
    # Discord Tokenがない場合にエラーで止まらないようチェックを入れるとより親切です
    if not DISCORD_TOKEN:
        print("Error: DISCORD_TOKEN is not set.")
    else:
        bot.run(DISCORD_TOKEN)
