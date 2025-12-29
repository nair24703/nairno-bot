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
    # 1. Groq AIで返答生成 (省略せずそのまま維持)
    try:
        chat_completion = client.chat.completions.create(
            messages=[
                {"role": "system", "content": "あなたは満別花丸という名前の女の子です。明るく元気に、語尾に「～だもん」や「～まる」をつけて喋ってください。"},
                {"role": "user", "content": user_text}
            ],
            model="llama-3.1-8b-instant",
        )
        response_text = chat_completion.choices[0].message.content
    except Exception as e:
        print(f"Groq Error: {e}")
        await interaction.followup.send("AIがお喋りをお休みしてるみたいだもん...。")
        return

    # 2. VOICEVOXでの音声合成
    voice_success = False
    voice_client = interaction.guild.voice_client

    if voice_client and voice_client.is_connected():
        try:
            # 非同期で通信するための「窓口」を作るまる
            async with httpx.AsyncClient() as httpx_client:
                # 1. レシピ作成 (audio_query)
                res1 = await httpx_client.post(
                    f'{VOICEVOX_URL}/audio_query', 
                    params={'text': response_text, 'speaker': HANAMARU_ID}, 
                    timeout=10.0
                )
                res1.raise_for_status()
                query_data = res1.json()

                # 2. 音声波形生成 (synthesis) - ここでBotを止めずに待つまる！
                res2 = await httpx_client.post(
                    f'{VOICEVOX_URL}/synthesis',
                    params={'speaker': HANAMARU_ID},
                    json=query_data,
                    timeout=60.0  # 長い文章でも大丈夫なように60秒待つまる
                )
                res2.raise_for_status()
                
                # 3. 保存
                with open("response.wav", "wb") as f:
                    f.write(res2.content)
            
            # 4. 再生
            ffmpeg_options = {
                'before_options': '-reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 5',
                'options': '-vn'
            }
            # 再生開始
            voice_client.play(discord.FFmpegPCMAudio("response.wav", **ffmpeg_options))
            voice_success = True

        except Exception as e:
            print(f"--- VOICE ERROR LOG ---")
            print(f"Error Type: {type(e).__name__}")
            print(f"Error Details: {e}")

    # 3. お返事
    if voice_success:
        await interaction.followup.send(f"**花丸**: {response_text}")
    else:
        await interaction.followup.send(f"（ごめんね、声が出ないから文字でお返事するまる！）\n**花丸**: {response_text}")

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
    embed.add_field(name="/stop", value="ボイスチャンネルからバイバイするまる。また遊ぼうね！", inline=False)
    embed.add_field(name="/kazu", value="今日の運勢を占うまる。めったに出ない大きな数を目指してね！", inline=False)
    embed.add_field(name="/omikuji", value="伏見稲荷大社風・AIおみくじを引くまる！", inline=False)
    embed.add_field(name="/help", value="このメニューを表示するまる。", inline=False)

    embed.set_footer(text="いつでも気軽に話しかけてほしいだもん！")
    
    await interaction.response.send_message(embed=embed, ephemeral=True)

@bot.tree.command(name="start", description="ボイスチャンネルに接続するまる！")
async def start(interaction: discord.Interaction):
    if interaction.user.voice:
        channel = interaction.user.voice.channel
        await channel.connect()
        await interaction.response.send_message(f"{channel.name} に接続したまる！話しかけてほしいだもん。")
    else:
        await interaction.response.send_message("まずはボイスチャンネルに入ってほしいだもん！")

@bot.tree.command(name="stop", description="ボイスチャンネルから切断するまる。")
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
@bot.tree.command(name="omikuji", description="伏見稲荷大社の17種類のおみくじを引くまる！")
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

    # AIへの指示を「おみくじの本文」風に変更するまる！
    prompt_content = (
        f"おみくじで「{result}」が出た人への『御神託（お告げ）』を書いて。 "
        f"「満別花丸」という巫女のような女の子として、古風な言い回しを混ぜつつ明るく伝えて。 "
        f"語尾は満別花丸のような「～だもん」や、「～まる」を使って、おみくじの紙に書いてあるような『教え』を2〜3文で短く書いてね。 "
        f"「AI」という言葉は絶対に使わないで。"
    )

    try:
        chat_completion = client.chat.completions.create(
            messages=[
                {"role": "system", "content": "あなたは満別花丸という、神社の手伝いをしている元気な女の子です。"},
                {"role": "user", "content": prompt_content}
            ],
            model="llama-3.3-70b-versatile",
        )
        ai_advice = chat_completion.choices[0].message.content
    except Exception as e:
        print(f"Groq API Error: {e}")
        ai_advice = f"神様との通信がちょっと途切れちゃったまる…。でも「{result}」は授かった大切な運勢だもん！大切に持ち帰ってほしいまる！"

    # 見た目も「AI」を消して、神社っぽくするまる！
    embed = discord.Embed(
        title="🦊 伏見稲荷大社・奉納おみくじ 🦊",
        description=f"あなたの運勢をお出ししたまる！\n\n**【 運 勢 】**\n# {result}",
        color=discord.Color.red()
    )
    # フィールド名を「御神託」や「教え」にするまる
    embed.add_field(name="✨ 花丸の御神託（おつげ）", value=ai_advice)
    embed.set_footer(text="伏見稲荷の伝統的な17種類。大切にするまるよ！")
    
    await interaction.followup.send(embed=embed)

# 7. より低い確率で大きい数が出るコマンド
@bot.tree.command(name="kazu", description="より低い確率で大きい数が出るまる！運試しにどうぞ！")
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
        comment = f"どんな卑怯なやり方をしたまる...？もうこれ以上の数は出ないまる...。宝くじ2等レベルの強運だもん！（1/1,000,000以下）"
    elif prob <= 1/100000:
        display = f"# {f_num}"
        comment = f"あなたは一体何度このコマンドを使用したまる...？これは手術の全身麻酔事故で死亡する確率に相当するまる。（1/100,000以下）"
    elif prob <= 1/10000:
        display = f"# {f_num}"
        comment = f"どうやってここまでたどり着いたまる？恐ろしい強運だもん。これは一生涯に落雷に遭う確率に相当するまる！（1/10,000以下）"
    elif prob <= 1/1000:
        display = f"## {f_num}"
        comment = f"すごすぎだもん！これは今日家を出たら事故に遭う確率に相当するまる。（1/1,000以下）"
    elif prob <= 1/100:
        display = f"**{f_num}**"
        comment = f"100分の1を超えたまる！（1/100以下）"
    else:
        display = f_num
        comment = ""

    await interaction.response.send_message(f"{display}\n{comment}")

# 【テスト用】kazuコマンドの全演出を確認するコマンド
@bot.tree.command(name="kazu_test", description="演出のテスト表示をするまる！")
async def kazu_test(interaction: discord.Interaction):
    test_cases = [
        (1/100, "100分の1（太字）"),
        (1/1000, "1,000分の1（中見出し）"),
        (1/10000, "10,000分の1（大見出し）"),
        (1/100000, "100,000分の1（大見出し：統一）"),
        (1/1000000, "1,000,000分の1（大見出し：統一）")
    ]
    
    dummy_results = [250, 5000, 800000, 1500000000, 999999999999999]
    responses = []

    for i, (prob, label) in enumerate(test_cases):
        f_num = f"{dummy_results[i]:,}"
        
        if prob <= 1/10000: # 1万分の1以下はすべて同じ「#」
            display = f"# {f_num}"
        elif prob <= 1/1000:
            display = f"## {f_num}"
        elif prob <= 1/100:
            display = f"**{f_num}**"
        else:
            display = f_num

        responses.append(f"【{label}】\n{display}")

    await interaction.response.send_message("\n\n".join(responses))

# --- 起動 ---
if __name__ == "__main__":
    keep_alive()
    bot.run(DISCORD_TOKEN)
