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
    chat_completion = client.chat.completions.create(
        messages=[
            {"role": "system", "content": "あなたは満別花丸という名前の女の子のキャラクターです。明るく元気に、語尾に「～だもん」や「～まる」をつけて喋ってください。"},
            {"role": "user", "content": user_text}
        ],
        model="llama3-8b-8192",
    )
    response_text = chat_completion.choices[0].message.content

    params = {'text': response_text, 'speaker': HANAMARU_ID}
    res1 = requests.post(f'{VOICEVOX_URL}/audio_query', params=params)
    res2 = requests.post(f'{VOICEVOX_URL}/synthesis', params={'speaker': HANAMARU_ID}, json=res1.json())
    
    with open("response.wav", "wb") as f:
        f.write(res2.content)

    if interaction.guild.voice_client:
        interaction.guild.voice_client.play(discord.FFmpegPCMAudio("response.wav"))
        await interaction.followup.send(f"**花丸**: {response_text}")
    else:
        await interaction.followup.send(f"ボイスチャンネルに接続していませんが、お返事するまる！：\n{response_text}")

# --- スラッシュコマンド定義 ---

# 5. ヘルプコマンド
@bot.tree.command(name="help", description="このBotの使い方とコマンド一覧を表示するまる！")
async def help_command(interaction: discord.Interaction):
    embed = discord.Embed(
        title="満別花丸 Bot 使い方ガイド",
        description="私はAI（Groq）とVOICEVOXを搭載した、お喋り大好きな女の子だもん！",
        color=discord.Color.pink()
    )
    embed.add_field(name="/start", value="ボイスチャンネルに接続するまる。お喋りする前に呼んでね！", inline=False)
    embed.add_field(name="/talk [メッセージ]", value="私とお喋りするコマンドだもん。声でお返事するまる！", inline=False)
    embed.add_field(name="/kazu", value="今日の運勢を占うまる。めったに出ない大きな数を目指してね！", inline=False)
    embed.add_field(name="/stop", value="ボイスチャンネルからバイバイするまる。また遊ぼうね！", inline=False)
    embed.add_field(name="/help", value="このメニューを表示するまる。", inline=False)
    
    embed.set_footer(text="いつでも気軽に話しかけてほしいだもん！")
    
    await interaction.response.send_message(embed=embed)

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