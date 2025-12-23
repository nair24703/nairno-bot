import discord
from discord.ext import commands
from groq import Groq
from discord import app_commands
import speech_recognition as sr
import requests, json, asyncio, os
import random
import math
from pydub import AudioSegment
from flask import Flask
from threading import Thread

app = Flask('')

@app.route('/')
def home():
    return "I'm alive"

def run():
    app.run(host='0.0.0.0', port=8000)

def keep_alive():
    t = Thread(target=run)
    t.start()

# --- 設定（環境変数から読み込む） ---
# GitHubには秘密鍵を載せず、後ほどKoyebの設定画面で入力します
DISCORD_TOKEN = os.getenv('DISCORD_TOKEN')
GROQ_API_KEY = os.getenv('GROQ_API_KEY')
VOICEVOX_URL = 'http://127.0.0.1:50021'
HANAMARU_ID = 69

# Groqクライアント
groq_client = Groq(api_key=GROQ_API_KEY)

# --- Botクラスの定義 ---
class MyBot(commands.Bot):
    def __init__(self):
        # すべての権限（Intents）を有効化
        intents = discord.Intents.all()
        super().__init__(command_prefix="!", intents=intents)

    async def setup_hook(self):
        # スラッシュコマンド（/kazuなど）をDiscordに登録
        await self.tree.sync()
        print("スラッシュコマンドを同期しました。")

bot = MyBot()

# --- 音声機能関連の関数 ---
def generate_voice(text):
    try:
        res1 = requests.post(f"{VOICEVOX_URL}/audio_query?text={text}&speaker={HANAMARU_ID}")
        res2 = requests.post(f"{VOICEVOX_URL}/synthesis?speaker={HANAMARU_ID}", data=json.dumps(res1.json()))
        with open("response.wav", "wb") as f: 
            f.write(res2.content)
    except Exception as e:
        print(f"VOICEVOX連携エラー: {e}")

async def finished_callback(sink, channel: discord.TextChannel, *args):
    print("録音データを解析中...")
    recognizer = sr.Recognizer()
    
    for user_id, audio in sink.audio_data.items():
        try:
            with open("temp_voice.wav", "wb") as f:
                f.write(audio.file.read())
            
            sound = AudioSegment.from_wav("temp_voice.wav")
            sound = sound.set_channels(1).set_frame_rate(16000)
            sound.export("user_voice.wav", format="wav")

            with sr.AudioFile("user_voice.wav") as source:
                recognizer.adjust_for_ambient_noise(source, duration=0.5)
                audio_data = recognizer.record(source)
                user_text = recognizer.recognize_google(audio_data, language='ja-JP')
            
            print(f"あなた: {user_text}")

            chat_completion = groq_client.chat.completions.create(
                messages=[
                    {"role": "system", "content": "あなたは満別花丸という女の子です。「〜だよ」「〜だね」と可愛く短く答えて。"},
                    {"role": "user", "content": user_text}
                ],
                model="llama3-70b-8192",
            )
            answer = chat_completion.choices[0].message.content
            print(f"花丸: {answer}")

            generate_voice(answer)
            vc = channel.guild.voice_client
            if vc:
                vc.play(discord.FFmpegPCMAudio("response.wav"))
                
        except sr.UnknownValueError:
            generate_voice("ごめんね、うまく聞き取れなかったよ。もう一回言って？")
            if channel.guild.voice_client:
                channel.guild.voice_client.play(discord.FFmpegPCMAudio("response.wav"))
        except Exception as e:
            print(f"解析エラー: {e}")

# --- Prefixコマンド (!start) ---
@bot.command()
async def start(ctx):
    if ctx.author.voice:
        vc = await ctx.author.voice.channel.connect()
        await ctx.send("満別花丸だよ！準備するね。")
        await asyncio.sleep(2)
        
        vc.start_recording(discord.sinks.WaveSink(), finished_callback, ctx.channel)
        await ctx.send("10秒間、お話を聞くよ！どうぞ！")
        
        await asyncio.sleep(10)
        if vc.recording:
            vc.stop_recording()
            await ctx.send("録音おわり！今考えるね。")
    else:
        await ctx.send("ボイスチャンネルに入ってね。")

# --- スラッシュコマンド (/kazu) ---
@bot.tree.command(name="kazu", description="2のn乗計算を実行します")
async def kazu(interaction: discord.Interaction):
    n = 0
    while random.random() < 0.9:
        n += 1

    base_value = 2 ** n
    variation_percent = random.randint(-100, 100)
    total_result = int(base_value + (base_value * (variation_percent / 100)))

    prob = 0.9 ** n
    
    if prob < 1/1000000:
        comment = "どんな卑怯なやり方をしたのですか...？このような数が出ることはないはずです。もうこれ以上の数は出ないと思ってください...。これは宝くじ2等が当たる確率に相当します。"
    elif prob < 1/100000:
        comment = "あなたは一体何度このコマンドを使用したのですか...？これは手術の全身麻酔事故で死亡する確率に相当しますよ。"
    elif prob < 1/10000:
        comment = "どうやってここまでたどり着いたのですか？？恐ろしい強運を持っていますね。これは一生涯に落雷に遭う確率に相当します。"
    elif prob < 1/1000:
        comment = "すごすぎです...。これは今日家を出たら事故に遭う確率に相当します。"
    elif prob < 1/100:
        comment = "100分の1を超えました！"
    else:
        comment = ""

    await interaction.response.send_message(f"{total_result}\n{comment}")

@bot.event
async def on_ready():
    print(f"ログインしました: {bot.user.name}")

# 起動
keep_alive()
bot.run(DISCORD_TOKEN)