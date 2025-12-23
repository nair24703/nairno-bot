import discord
from discord import app_commands
from discord.ext import commands
import os
import asyncio
from groq import Groq
import requests
import random
import math
from pydub import AudioSegment
from flask import Flask
from threading import Thread

# --- Flask (Koyebヘルスチェック回避用) ---
app = Flask('')
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
VOICEVOX_URL = 'http://localhost:50021'
HANAMARU_ID = 69 

client = Groq(api_key=GROQ_API_KEY)

intents = discord.Intents.default()

class MyBot(commands.Bot):
    def __init__(self):
        super().__init__(command_prefix="!", intents=intents)

    async def setup_hook(self):
        await self.tree.sync()
        print(f"Synced slash commands for {self.user}")

bot = MyBot()

# --- 共通の対話ロジック ---
async def process_voice_interaction(interaction: discord.Interaction, user_text: str):
    # Groq AIで返答生成
    chat_completion = client.chat.completions.create(
        messages=[
            {"role": "system", "content": "あなたは満別花丸という名前の女の子のキャラクターです。明るく元気に、語尾に「～だもん」や「～まる」をつけて喋ってください。"},
            {"role": "user", "content": user_text}
        ],
        model="llama3-8b-8192",
    )
    response_text = chat_completion.choices[0].message.content

    # ボイスクライアント（接続状態）を確認
    voice_client = interaction.guild.voice_client

    if voice_client and voice_client.is_connected():
        # --- ボイスチャンネルに接続している場合：声も出す ---
        params = {'text': response_text, 'speaker': HANAMARU_ID}
        res1 = requests.post(f'{VOICEVOX_URL}/audio_query', params=params)
        res2 = requests.post(f'{VOICEVOX_URL}/synthesis', params={'speaker': HANAMARU_ID}, json=res1.json())
        
        with open("response.wav", "wb") as f:
            f.write(res2.content)

        # 再生（FFmpeg）
        voice_client.play(discord.FFmpegPCMAudio("response.wav"))
        await interaction.followup.send(f"**花丸**: {response_text}")
    else:
        # --- 接続していない場合：テキストのみでお返事 ---
        await interaction.followup.send(f"（ボイスチャンネルにいないので、文字だけでお返事するまる！）\n**花丸**: {response_text}")

# --- スラッシュコマンド定義 ---

# 5. ヘルプコマンド
@bot.tree.command(name="help", description="このBotの使い方とコマンド一覧を表示するまる！")
async def help_command(interaction: discord.Interaction):
    embed = discord.Embed(
        title="ネアーノ（満別花丸）Bot 使い方ガイド",
        description="私はAI（Groq）とVOICEVOXを搭載した、お喋り大好きな女の子だもん！",
        color=discord.Color.pink()
    )
    embed.add_field(name="/start", value="ボイスチャンネルに接続するまる。お喋りする前に呼んでね！", inline=False)
    embed.add_field(name="/talk [メッセージ]", value="私とお喋りするコマンドだもん。声でお返事するまる！", inline=False)
    embed.add_field(name="/kazu", value="今日の運勢を占うまる。めったに出ない大きな数を目指してね！", inline=False)
    embed.add_field(name="/stop", value="ボイスチャンネルからバイバイするまる。また遊ぼうね！", inline=False)
    embed.add_field(name="/help", value="このメニューを表示するまる。", inline=False)
    
    embed.set_footer(text="いつでも気軽に話しかけてほしいだもん！")
    
    await interaction.response.send_message(embed=embed, ephemeral=True)

@bot.tree.command(name="start", description="ボイスチャンネルに接続して対話を開始します")
async def start(interaction: discord.Interaction):
    if interaction.user.voice:
        channel = interaction.user.voice.channel
        await channel.connect()
        await interaction.response.send_message(f"{channel.name} に接続したまる！話しかけてほしいだもん。")
    else:
        await interaction.response.send_message("まずはボイスチャンネルに入ってほしいだもん！")

@bot.tree.command(name="stop", description="ボイスチャンネルから切断します")
async def stop(interaction: discord.Interaction):
    if interaction.guild.voice_client:
        await interaction.guild.voice_client.disconnect()
        await interaction.response.send_message("バイバイだもん！また呼んでね。")
    else:
        await interaction.response.send_message("今はどこにも繋がっていないまる。")

@bot.tree.command(name="talk", description="花丸とお喋りするまる！")
@app_commands.describe(message="話したい内容を入力してね")
async def talk(interaction: discord.Interaction, message: str):
    await interaction.response.defer()
    await process_voice_interaction(interaction, message)

# 6. 伏見稲荷大社風・本格おみくじコマンド (AIアドバイス修正版)
@bot.tree.command(name="omikuji", description="伏見稲荷大社の17種類のおみくじを引き、AIがアドバイスするまる！")
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

    # AIへの指示（プロンプト）をより明確にする
    prompt_content = f"おみくじの結果「{result}」が出た人に対して、明るく元気な女の子「満別花丸」としてアドバイスして。語尾は「～だもん」「～まる」にして、2〜3文で短く話してね。"

    try:
        # 非同期でGroqを呼び出す（もしエラーが続くならここを修正するまる）
        chat_completion = client.chat.completions.create(
            messages=[
                {"role": "system", "content": "あなたは満別花丸です。"},
                {"role": "user", "content": prompt_content}
            ],
            model="llama3-8b-8192",
        )
        ai_advice = chat_completion.choices[0].message.content
    except Exception as e:
        # どんなエラーが出ているかKoyebのログに出力する（これで原因がわかるまる！）
        print(f"Groq API Error: {e}")
        ai_advice = f"ごめんね、いまちょっと知恵熱が出ちゃったまる…。でも「{result}」はとっても大切な運勢だもん！今日も一日応援してるまる！"

    embed = discord.Embed(
        title="🦊 伏見稲荷大社風・AIおみくじ 🦊",
        description=f"あなたの運勢を占ったまる！\n\n**{result}**",
        color=discord.Color.red()
    )
    embed.add_field(name="花丸からのAIアドバイス", value=ai_advice)
    embed.set_footer(text="伏見稲荷の17種類を完全再現したまる！")
    
    await interaction.followup.send(embed=embed)

# 7. より低い確率で大きい数が出るコマンド
@bot.tree.command(name="kazu", description="より低い確率で大きい数が出ます。")
async def kazu(interaction: discord.Interaction):
    n = 0
    while random.random() < 0.9:
        n += 1

    base_value = 2 ** n
    variation_percent = random.randint(-100, 100)
    total_result = int(base_value + (base_value * (variation_percent / 100)))

    prob = 0.9 ** n
    
    if prob < 1/1000000:
        comment = "どんな卑怯なやり方をしたまる...？もうこれ以上の数は出ないまる...。宝くじ2等レベルの強運だもん！"
    elif prob < 1/100000:
        comment = "あなたは一体何度このコマンドを使用したまる...？これは手術の全身麻酔事故で死亡する確率に相当するまる。"
    elif prob < 1/10000:
        comment = "どうやってここまでたどり着いたまる？恐ろしい強運だもん。これは一生涯に落雷に遭う確率に相当するまる！"
    elif prob < 1/1000:
        comment = "すごすぎだもん！これは今日家を出たら事故に遭う確率に相当するまる。"
    elif prob < 1/100:
        comment = "100分の1を超えたまる！" 
    else:
        comment = ""

    await interaction.response.send_message(f"**{total_result}**\n{comment}")

# --- 起動 ---
if __name__ == "__main__":
    keep_alive()
    bot.run(DISCORD_TOKEN)