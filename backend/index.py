import os
import requests
import json
import re
import time
import urllib.parse # 🚨 新增：用于 URL 转码
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from dotenv import load_dotenv

from docx import Document
from docx.shared import Pt

load_dotenv(override=True)

app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = 'uploads'
OUTPUT_FOLDER = 'outputs'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

def get_model_config():
    return {
        "deepseek": {"url": os.getenv("DEEPSEEK_URL"), "key": os.getenv("DEEPSEEK_KEY"), "model": "deepseek-chat"},
        "kimi": {"url": os.getenv("KIMI_URL"), "key": os.getenv("KIMI_KEY"), "model": "moonshot-v1-8k"},
        "doubao": {"url": "https://ark.cn-beijing.volces.com/api/v3/responses", "key": os.getenv("DOUBAO_KEY"), "model": "doubao-seed-2-0-pro-260215"}
    }

def process_document_with_agent(filepath, original_filename, question, system_prompt, config):
    try:
        doc = Document(filepath)
        paragraphs_text = [p.text for p in doc.paragraphs if p.text.strip()]
        full_text = "\n".join(paragraphs_text)

        agent_prompt = f"""你是一个专业的文档排版与润色智能体。
用户指令：{question}

文档内容如下：
{full_text}

请严格按以下JSON格式返回修改建议（不要返回任何Markdown解释，只返回纯JSON字符串）：
{{
  "rewrite_tasks": [
    {{"target_text": "需要被替换的原句子", "new_text": "润色后的新句子"}}
  ],
  "format_tasks": [
    {{"target": "body_text", "font_name": "SimSun", "font_size": 14}}
  ]
}}
注：如果没有对应的任务，数组保留为空即可。如果用户要求改字体，font_name 填英文字体名（如黑体为 SimHei，宋体为 SimSun）。
"""

        payload = {
            "model": config["model"],
            "messages": [{"role": "system", "content": system_prompt}, {"role": "user", "content": agent_prompt}]
        }

        headers = {"Authorization": f"Bearer {config['key']}", "Content-Type": "application/json"}
        resp = requests.post(config["url"], headers=headers, json=payload, timeout=300)
        result = resp.json()
        
        if "choices" not in result or len(result["choices"]) == 0:
            err_msg = result.get("error", {}).get("message", "API返回的数据异常")
            return jsonify({"content": f"大模型接口拒绝了请求，原因：\n{err_msg}", "source": "系统"})

        answer = result["choices"][0]["message"].get("content", "").strip()
        start_idx = answer.find('{')
        end_idx = answer.rfind('}')
        
        if start_idx != -1 and end_idx != -1:
            json_str = answer[start_idx:end_idx+1]
            json_str = re.sub(r',\s*([\]}])', r'\1', json_str)
            instructions = json.loads(json_str, strict=False)
        else:
            raise ValueError(f"大模型没有返回包含 {{}} 的有效 JSON 数据。原回复：\n{answer}")

        for task in instructions.get("rewrite_tasks", []):
            old_text = task.get("target_text", "")
            new_text = task.get("new_text", "")
            if old_text and new_text:
                for p in doc.paragraphs:
                    if old_text in p.text:
                        p.text = p.text.replace(old_text, new_text)

        for task in instructions.get("format_tasks", []):
            target = task.get("target")
            font_name = task.get("font_name")
            font_size = task.get("font_size")
            if target == "body_text":
                for p in doc.paragraphs:
                    for run in p.runs:
                        if font_name: run.font.name = font_name
                        if font_size: run.font.size = Pt(font_size)

        timestamp = int(time.time())
        output_filename = f"修改后_{timestamp}_{original_filename}"
        output_path = os.path.join(OUTPUT_FOLDER, output_filename)
        doc.save(output_path)
        
        # 🚨 核心修复：对带有中文的文件名进行 URL 编码，防止 Flutter 解析崩溃！
        encoded_filename = urllib.parse.quote(output_filename)
        file_url = f"http://{request.host}/api/download/{encoded_filename}"

        return jsonify({
            "content": "✅ 文档已智能排版与润色完毕！\n请点击下方文件卡片导出至手机。",
            "source": "文档专家",
            "file_path": file_url  
        })

    except json.JSONDecodeError:
        return jsonify({"content": f"处理失败：提取出的指令不是标准JSON格式。\n大模型原回复：\n{answer}", "source": "系统"})
    except Exception as e:
        return jsonify({"content": f"文档处理本地执行异常：{str(e)}", "source": "系统"})

@app.route('/api/chat', methods=['POST'])
def chat():
    if request.content_type and 'multipart/form-data' in request.content_type:
        data = request.form
        question = data.get('question', '').strip()
        system_prompt = data.get('system_prompt', '你是一个AI助手')
        model = data.get('model', 'kimi') 
        
        document = request.files.get('document')
        if not document or document.filename == '':
            return jsonify({"content": "未接收到有效的文档文件", "source": "错误"})

        try:
            original_filename = document.filename.replace('/', '_').replace('\\', '_') 
            safe_input_filename = f"upload_{int(time.time())}_{original_filename}"
            input_path = os.path.join(UPLOAD_FOLDER, safe_input_filename)
            document.save(input_path)
            
            config = get_model_config()[model]
            return process_document_with_agent(input_path, original_filename, question, system_prompt, config)
        except Exception as e:
            return jsonify({"content": f"文件保存或处理失败: {str(e)}", "source": "错误"})

    else:
        data = request.json
        question = data.get('question', '').strip()
        image_data = data.get('image_data')
        model = data.get('model', 'deepseek')
        system_prompt = data.get('system_prompt', '你叫小陆，是圆圆的贴心助手。')

        if image_data: model = "doubao"
        config = get_model_config()[model]
        headers = {"Authorization": f"Bearer {config['key']}", "Content-Type": "application/json"}

        try:
            if model == "doubao":
                content = []
                if image_data: content.append({"type": "input_image", "image_url": f"data:image/png;base64,{image_data}"})
                content.append({"type": "input_text", "text": question if question else "描述这张图片"})
                payload = {"model": config["model"], "input": [{"role": "user", "content": content}]}
            else:
                payload = {"model": config["model"], "messages": [{"role": "system", "content": system_prompt}, {"role": "user", "content": question}]}

            resp = requests.post(config["url"], headers=headers, json=payload, timeout=90)
            result = resp.json()
            answer = ""

            if "output" in result:
                for out in result["output"]:
                    if out.get("type") == "message":
                        for c in out.get("content", []):
                            if c.get("type") == "output_text":
                                answer = c.get("text", "").strip()
                                break
                        break
            elif "choices" in result and len(result["choices"]) > 0:
                answer = result["choices"][0]["message"].get("content", "").strip()

            if not answer:
                answer = f"提示：{result.get('error', {}).get('message', '服务暂时无法回复')}"

            return jsonify({"content": answer, "source": {"deepseek": "DeepSeek", "kimi": "Kimi", "doubao": "豆包"}.get(model, "AI")})

        except Exception as e:
            return jsonify({"content": f"服务异常，请稍后再试: {str(e)}", "source": "系统"})

# 🚨 新增：让手机能够下载文件的专属接口
@app.route('/api/download/<path:filename>', methods=['GET'])
def download_file(filename):
    return send_from_directory(OUTPUT_FOLDER, filename, as_attachment=True)

if __name__ == '__main__':
    host = os.getenv("FLASK_HOST", "0.0.0.0")
    port = int(os.getenv("FLASK_PORT", 5000))
    app.run(host=host, port=port, debug=False)