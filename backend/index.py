import os
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

load_dotenv(override=True)

app = Flask(__name__)
CORS(app)

def get_model_config():
    return {
        "deepseek": {
            "url": os.getenv("DEEPSEEK_URL"),
            "key": os.getenv("DEEPSEEK_KEY"),
            "model": "deepseek-chat"
        },
        "kimi": {
            "url": os.getenv("KIMI_URL"),
            "key": os.getenv("KIMI_KEY"),
            "model": "moonshot-v1-8k"
        },
        "doubao": {
            "url": "https://ark.cn-beijing.volces.com/api/v3/responses",
            "key": os.getenv("DOUBAO_KEY"),
            "model": "doubao-seed-2-0-pro-260215",
        }
    }

@app.route('/api/chat', methods=['POST'])
def chat():
    data = request.json
    question = data.get('question', '').strip()
    image_data = data.get('image_data')
    model = data.get('model', 'deepseek')

    # 有图片强制走豆包
    if image_data:
        model = "doubao"

    config = get_model_config()[model]
    headers = {
        "Authorization": f"Bearer {config['key']}",
        "Content-Type": "application/json"
    }

    try:
        # 豆包 Seed 2.0 格式（看图）
        if model == "doubao":
            content = []
            if image_data:
                content.append({
                    "type": "input_image",
                    "image_url": f"data:image/png;base64,{image_data}"
                })
            content.append({
                "type": "input_text",
                "text": question if question else "描述这张图片"
            })
            payload = {
                "model": config["model"],
                "input": [{
                    "role": "user",
                    "content": content
                }]
            }
        # 普通文本模型（DeepSeek / Kimi）
        else:
            payload = {
                "model": config["model"],
                "messages": [
                    {"role": "system", "content": "你叫小陆，是圆圆的贴心助手。"},
                    {"role": "user", "content": question}
                ]
            }

        # 请求接口
        resp = requests.post(config["url"], headers=headers, json=payload, timeout=90)
        result = resp.json()

        # 统一干净提取回答
        answer = ""

        # 豆包返回格式
        if "output" in result:
            for out in result["output"]:
                if out.get("type") == "message":
                    for c in out.get("content", []):
                        if c.get("type") == "output_text":
                            answer = c.get("text", "").strip()
                            break
                    break

        # DeepSeek / Kimi 返回格式
        elif "choices" in result and len(result["choices"]) > 0:
            msg = result["choices"][0]["message"]
            answer = msg.get("content", "").strip()

        # 错误提示精简
        if not answer:
            err = result.get("error", {}).get("message", "服务暂时无法回复")
            answer = f"提示：{err}"

        # 只返回纯文字，APP显示最干净
        return jsonify({
            "content": answer,
            "source": {
                "deepseek": "DeepSeek",
                "kimi": "Kimi",
                "doubao": "豆包"
            }.get(model, "AI")
        })

    except Exception as e:
        return jsonify({
            "content": f"服务异常，请稍后再试",
            "source": "系统"
        })

if __name__ == '__main__':
    host = os.getenv("FLASK_HOST", "0.0.0.0")
    port = int(os.getenv("FLASK_PORT", 5000))
    app.run(host=host, port=port, debug=False)