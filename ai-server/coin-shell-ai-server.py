from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel,Field
import httpx
import os
import json
import re
from dotenv import load_dotenv
import uvicorn
import redis 

load_dotenv()

app = FastAPI(title="AI 记账助手", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ========== Redis 连接 ==========
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
REDIS_DB = int(os.getenv("REDIS_DB", 0))
r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=REDIS_DB, decode_responses=True)

# ========== 请求/响应模型 ==========
class ParseRequest(BaseModel):
    text: str
    session_id: str = Field(..., alias='sessionId')
    user_id: int = Field(..., alias='userId')
    class Config:
        populate_by_name = True  # 允许通过字段名或别名填充

class ParseResponse(BaseModel):
    amount: float
    type: int = 2
    category: str
    note: str

# ========== 记忆相关函数 ==========
MAX_HISTORY = 12  # 保留最近 6 轮对话（12 条消息）

def get_history(user_id: int, session_id: str) -> list:
    """从 Redis 获取历史消息列表（按用户隔离）"""
    key = f"chat:{user_id}:{session_id}"   # ✅ 组合 Key
    data = r.get(key)
    return json.loads(data) if data else []

def update_history(user_id: int, session_id: str, user_msg: str, assistant_msg: str) -> None:
    """存储历史，并截断到最大长度"""
    history = get_history(user_id, session_id)  # ✅ 传入 user_id
    history.append({"role": "user", "content": user_msg})
    history.append({"role": "assistant", "content": assistant_msg})
    if len(history) > MAX_HISTORY:
        history = history[-MAX_HISTORY:]
    key = f"chat:{user_id}:{session_id}"   # ✅ 组合 Key
    r.setex(key, 86400 * 7, json.dumps(history))

# ========== JSON 修复函数（保持不变） ==========
def repair_json(text: str) -> str:
    text = re.sub(r'(")\s+(")', r'\1,\2', text)
    text = re.sub(r'(\})\s*(")', r'\1,\2', text)
    if text.count('{') > text.count('}'):
        text += '}'
    text = re.sub(r'(\d)\s+(")', r'\1,\2', text)
    text = re.sub(r'"\s+(\w+)"', r'"\1"', text)
    text = re.sub(r'\s+', ' ', text)
    return text

# ========== 健康检查 ==========
@app.get("/")
async def root():
    return {"message": "AI 记账助手已启动", "status": "running"}

@app.get("/ping")
async def ping():
    return {"pong": True}

# ========== 核心 AI 接口 ==========
@app.post("/ai/parse", response_model=ParseResponse)
async def parse_bill(request: ParseRequest):
    # 1. 获取历史
    history = get_history(request.user_id,request.session_id)

    # 2. 构建完整的 messages（系统提示 + 历史 + 当前问题）
    system_prompt = {
        "role": "system",
        "content": """你是一个记账助手。请将用户输入的记账文本解析为 JSON 格式。
只返回 JSON，不要有其他内容。
JSON 格式：{"amount": 数字金额, "category": "分类", "note": "备注"}
分类只能是：餐饮、交通、购物、娱乐、住房、通讯、医疗、教育、工资、理财、兼职、红包、其他
金额必须是数字，不要带单位。"""
    }
    messages = [system_prompt] + history
    messages.append({"role": "user", "content": request.text})

    try:
        api_key = os.getenv("DEEPSEEK_API_KEY", "")
        if not api_key:
            raise HTTPException(status_code=500, detail="请设置 DEEPSEEK_API_KEY 环境变量")

        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(
                "https://api.siliconflow.cn/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "deepseek-ai/DeepSeek-V4-Flash",
                    "messages": messages,   #  使用完整的历史消息
                    "temperature": 0.1
                }
            )

            if resp.status_code != 200:
                raise HTTPException(status_code=resp.status_code, detail="大模型 API 调用失败")

            result = resp.json()
            content = result["choices"][0]["message"]["content"]
            print(f"AI 返回内容: {content}")

            # 提取 JSON
            json_match = re.search(r'\{.*\}', content, re.DOTALL)
            if not json_match:
                raise HTTPException(status_code=500, detail="AI 返回内容未包含有效 JSON")

            raw_json = json_match.group()
            try:
                data = json.loads(raw_json)
            except json.JSONDecodeError:
                print(f"原始 JSON 格式有误，尝试修复: {raw_json}")
                fixed_json = repair_json(raw_json)
                print(f"修复后: {fixed_json}")
                data = json.loads(fixed_json)

            # 提取字段
            amount = float(data.get("amount", 0))
            category = data.get("category", "其他")
            note = data.get("note", request.text)

            # 根据分类推断类型
            income_categories = ["工资", "兼职", "理财", "红包", "奖金"]
            record_type = 1 if category in income_categories else 2

            friendly_message = f"记账成功：{category} {amount:.2f} 元"
            # 存储本次对话历史
            update_history(request.user_id, request.session_id, request.text, friendly_message)

            return ParseResponse(
                amount=amount,
                type=record_type,
                category=category,
                note=note
            )

    except json.JSONDecodeError as e:
        raise HTTPException(status_code=500, detail=f"JSON 解析失败: {str(e)}")
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="大模型 API 请求超时")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"解析失败: {str(e)}")

# ========== 获取历史消息接口 ==========
class HistoryMessage(BaseModel):
    role: str   # "user" 或 "assistant"
    content: str

@app.get("/history/{session_id}")
async def get_chat_history(session_id: str, user_id: int):
    """根据 user_id 和 session_id 返回历史消息列表"""
    history = get_history(user_id, session_id)   #  传入 user_id
    return history

# ========== 启动入口 ==========
if __name__ == "__main__":
    uvicorn.run("coin-shell-ai-server:app", host="0.0.0.0", port=8000, reload=True)