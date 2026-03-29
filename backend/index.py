import os
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app) # 开启跨域支持

# 【配置区】
DEEPSEEK_KEY = "sk-028c375fb721407e9fd742422020fd9d"
GAODE_KEY = "88ef6f0a034af78ee56fae50b060c855"
API_URL = "https://api.deepseek.com/chat/completions"

def get_real_traffic():
    """高德 API 实时抓取：西湖断桥附近的交通态势"""
    url = f"https://restapi.amap.com/v3/traffic/status/circle?location=120.15,30.27&radius=1500&key={GAODE_KEY}"
    try:
        res = requests.get(url, timeout=5)
        data = res.json()
        if data.get('status') == '1' and 'trafficinfo' in data:
            info = data['trafficinfo']
            status_desc = info.get('description', '路况平稳')
            return f"【高德实时路况】{status_desc}。"
        return "【高德提示】该区域暂无详细路况数据。"
    except:
        return "【高德提示】获取实时路况超时。"

def get_smart_intent(question):
    """【黑科技】：利用 AI 识别用户的语义意图"""
    prompt = f"""
    你是一个意图分类器。请分析用户的话，从以下三个分类中选择一个最合适的：
    - commute: 询问路况、地点、导航、打车、出门、天气或交通。
    - academic: 询问论文、摘要、翻译、专业知识、总结或学术格式。
    - default: 闲聊、日常问候或其他通用问题。
    
    用户说的话: "{question}"
    
    只需回答分类 ID（commute/academic/default），不要回答任何其他文字。
    """
    try:
        response = requests.post(
            API_URL,
            headers={"Authorization": f"Bearer {DEEPSEEK_KEY}"},
            json={
                "model": "deepseek-chat",
                "messages": [{"role": "system", "content": "You are a classifier."}, {"role": "user", "content": prompt}],
                "temperature": 0 # 识别意图需要极度准确
            },
            timeout=10
        )
        intent = response.json()['choices'][0]['message']['content'].strip().lower()
        return intent if intent in ['commute', 'academic', 'default'] else 'default'
    except:
        return 'default'

@app.route('/api/chat', methods=['POST'])
def chat():
    data = request.json
    question = data.get('question', '')
    
    # --- 1. 语义意图识别 ---
    intent = get_smart_intent(question)
    print(f">>> AI 识别到的意图为: {intent}")

    # --- 2. 根据意图动态调整身份和背景数据 ---
    # 强制注入“小陆”身份，亲切称呼圆圆
    system_prompt = "你叫小陆，是圆圆的专职智能助手。你要表现得非常贴心，一定要称呼用户为‘圆圆’。"
    source_name = "智能内核"

    if intent == "commute":
        source_name = "小陆·通勤助手"
        traffic_info = get_real_traffic()
        system_prompt += f"\n当前是通勤模式。背景信息：{traffic_info}。请根据这个路况给圆圆温馨的出行建议。"
    
    elif intent == "academic":
        source_name = "小陆·学术助理"
        system_prompt += "\n当前是学术模式。请以专业、严谨且结构化的口吻协助圆圆处理学术任务。"

    # --- 3. 正式向 DeepSeek 请求对话 ---
    try:
        response = requests.post(
            API_URL,
            headers={"Authorization": f"Bearer {DEEPSEEK_KEY}"},
            json={
                "model": "deepseek-chat",
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": question}
                ],
                "temperature": 0.7
            },
            timeout=30
        )
        
        result = response.json()
        ai_content = result['choices'][0]['message']['content']
        
        return jsonify({
            "content": ai_content, 
            "source": source_name
        })
        
    except Exception as e:
        return jsonify({"content": f"对话请求失败: {str(e)}", "source": "后端报错"})

if __name__ == '__main__':
    # 锁定你的热点 IP，穿透 VPN
    app.run(host='192.168.81.221', port=5000, debug=True)