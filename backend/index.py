import os
import requests
from flask import Flask, request, jsonify

app = Flask(__name__)

# 【配置区】你的专属 Key
DEEPSEEK_KEY = "sk-028c375fb721407e9fd742422020fd9d"
GAODE_KEY = "88ef6f0a034af78ee56fae50b060c855"

def get_real_traffic():
    """高德 API 实时抓取：西湖断桥附近的交通态势"""
    # 坐标：120.15, 30.27 (西湖断桥附近)
    url = f"https://restapi.amap.com/v3/traffic/status/circle?location=120.15,30.27&radius=1500&key={GAODE_KEY}"
    try:
        res = requests.get(url, timeout=5)
        data = res.json()
        if data.get('status') == '1' and 'trafficinfo' in data:
            info = data['trafficinfo']
            # 拼接实时路况信息
            status_desc = info.get('description', '路况平稳')
            evaluation = info.get('evaluation', {}).get('expedite', '未知')
            return f"【高德实时路况】{status_desc}。总体评价：{evaluation}。"
        return "【高德提示】坐标点暂无详细路况数据。"
    except Exception as e:
        print(f"高德请求失败: {e}")
        return "【高德提示】路况接口连接超时，请稍后再试。"

@app.route('/api/chat', methods=['POST'])
def chat():
    data = request.json
    question = data.get('question', '')
    
    # 强制注入“小陆”身份
    system_prompt = "你叫小陆，是圆圆的专职智能通勤助手。你要表现得非常贴心，称呼用户为‘圆圆’。"
    
    # 意图判断：是否问了关于路况、去向、堵车等问题
    is_commute = any(k in question for k in ["西湖", "堵", "路况", "去", "走", "车", "多长时间", "断桥"])
    
    traffic_context = ""
    if is_commute:
        print(">>> 检测到通勤意图，正在抓取高德真实数据...")
        traffic_context = get_real_traffic()
        # 把真实数据塞进背景里，让 AI 看着数据说话
        system_prompt += f"\n\n当前实时背景信息：{traffic_context}"

    try:
        print(f"正在向 DeepSeek 请求对话... (当前背景: {'通勤模式' if is_commute else '普通模式'})")
        response = requests.post(
            "https://api.deepseek.com/chat/completions",
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
            "source": "小陆智能通勤助手" if is_commute else "云端大脑"
        })
        
    except Exception as e:
        return jsonify({"content": f"后端连接 DeepSeek 失败: {str(e)}", "source": "后端报错"})

if __name__ == '__main__':
    # 暴力锁定：直接填入你查到的手机热点分配给电脑的 IP
    # 这样 Flask 就会绕过 VPN 的虚拟网卡，专门守在热点这个“门口”
    app.run(host='192.168.81.221', port=5000, debug=True)