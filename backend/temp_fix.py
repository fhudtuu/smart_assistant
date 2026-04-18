    def ask(self, question: str, model: str = '') -> Dict:
        """使用RAG回答问题（优先RAG，fallback到LLM）"""
        # 1. 先尝试 RAG 检索
        relevant_docs = self.retrieve(question)

        if relevant_docs and relevant_docs[0]['score'] > 0.05:
            # 有RAG数据且相关性足够，用RAG回答
            context = '\n\n'.join([doc['content'] for doc in relevant_docs])
            answer = self._generate_answer(question, context, relevant_docs)
            return {
                'content': answer,
                'source': relevant_docs[0]['metadata'].get('chip_name', '数据手册')
            }

        # 2. 没有上传PDF或相关性低时，fallback到LLM回答
        from dotenv import load_dotenv
        load_dotenv(override=True)

        API_KEY = os.getenv('')
        API_URL = os.getenv('')

        print(f"[DATASHEET] LLM Fallback - KEY: {API_KEY[:10] if API_KEY else 'None'}, URL: {API_URL}")

        if API_KEY and API_URL:
            headers = {
                "Authorization": f"Bearer {API_KEY}",
                "Content-Type": "application/json"
            }
            payload = {
                "model": "",
                "messages": [
                    {"role": "system", "content": "你是一个专业的嵌入式系统工程师，擅长回答单片机、芯片、嵌入式开发相关问题。回答要专业、简洁、有技术深度。"},
                    {"role": "user", "content": question}
                ],
                "temperature": 0.7
            }
            try:
                resp = requests.post(API_URL, headers=headers, json=payload, timeout=60)
                result = resp.json()
                print(f"[DATASHEET] LLM响应: {result}")

                if "choices" in result and len(result["choices"]) > 0:
                    llm_answer = result["choices"][0]["message"]["content"].strip()
                    return {
                        'content': llm_answer,
                        'source': '嵌入式助手'
                    }
            except Exception as e:
                print(f"LLM调用失败: {e}")
                pass

        # 3. 连API都失败了，返回友好提示
        return {
            'content': '抱歉，没有找到相关的文档内容，也没有连接到AI服务。\n\n请尝试：\n1. 上传数据手册PDF文件\n2. 检查后端服务是否正常运行\n3. 确认 .env 中的 API 配置正确',
            'source': None
        }
