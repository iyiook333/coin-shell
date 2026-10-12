# Coin Shell

一个积分权益系统的完整实现：Spring Boot 后端 + HarmonyOS 客户端 + Python AI 服务。

用户通过每日签到、限时抢购等活动获取金币，金币可按比例兑换为现金并记录收益流水。
本仓库的重点不在"网赚玩法"，而在于**活动类场景下的一致性处理**：如何在并发请求中不超卖、
不重复发放，以及在缓存与数据库之间保证最终一致。

## 模块

| 模块 | 技术栈 | 说明 |
|---|---|---|
| `backend` | Spring Boot 3 + MyBatis-Plus + MySQL + Redis/Redisson | 业务后端，登录态、签到、抢购、资产与流水 |
| `harmonyos` | HarmonyOS ArkTS | 客户端，11 个页面 |
| `ai-server` | FastAPI + httpx | 自然语言记账解析（把一句话转成结构化记账数据） |

## 值得一看的设计

### 1. 限时抢购：三重防护保证不超卖

`FlashGrabServiceImpl#grab` 是并发控制最集中的一处，按顺序做了三层防护：

1. **Redisson 分布式锁**（按 `日期 + 活动ID` 加锁）——挡住同一活动的并发进入；
2. **Redis 原子扣减库存**——`decrement` 后若发现 `remaining < 0`，立即 `increment` 补偿回滚，
   这是超卖的最后一道闸；
3. **MySQL 唯一索引兜底**——`(user_id, activity_id, grab_date)` 唯一约束，
   插入抛 `DuplicateKeyException` 时回滚 Redis 库存并返回"已领取"。

外层包 `@Transactional(rollbackFor = Exception.class)`，Redis 扣减与 DB 写入在同一段临界区内完成。
缓存未初始化时用双检加锁（Double-Checked Locking）初始化，避免并发重建。

预热任务 `FlashQuotaPreheatTask` 在活动开始前 10 秒把当日库存写入 Redis，
避免活动开启瞬间的缓存击穿。

### 2. 连续签到天数：一条窗口函数 SQL

`SignRecordMapper` 用手写 SQL 计算连续签到，而不是在 Java 里循环：

```sql
ROW_NUMBER() OVER (ORDER BY sign_date DESC) AS rn
-- 连续的天数满足：今天 - 签到日期 = 序号 - 1
DATEDIFF(#{today}, sign_date) = rn - 1
```

思路是把"日期差"和"行号"对齐，一旦中断两者就不再相等，取满足条件的最大行号即为连续天数。
把这段逻辑交给数据库比拉全量记录到内存再遍历更省内存，也更准确。

### 3. 签到缓存：事务提交后再写 Redis

`SignEventListener` 用 `@TransactionalEventListener(phase = AFTER_COMMIT)` 监听签到事件，
**只在数据库事务提交成功后**才写 Redis Bitmap，并捕获异常仅记日志。

取舍是明确的：Redis 写失败不能让用户已经成功的签到被回滚（主流程优先），
缓存不一致由补偿任务兜底。反过来如果先写缓存再提交事务，事务回滚就会留下脏缓存。

### 4. 资产流水：所有变动可追溯

每次金币变动都会写入 `EarningsDetail`，记录变动后余额、来源类型与来源 ID，
资产统计（总览 / 分类 / 趋势）都基于流水聚合而非直接读余额字段。

## 本地运行

### 后端

```bash
cd backend
mvn spring-boot:run
```

需要本地 MySQL（库名 `coin-shell`）与 Redis。数据库密码通过环境变量注入，不要写进配置文件：

```bash
export MYSQL_PASSWORD=your_password
```

### HarmonyOS 客户端

用 DevEco Studio 打开 `harmonyos/`。客户端默认请求 `http://10.0.2.2:8080`（模拟器映射到宿主机）。

### AI 服务

```bash
cd ai-server
pip install -r requirements.txt
cp .env.example .env
python coin-shell-ai-server.py
```

需要在 `.env` 中配置模型服务商的 API Key。该服务调用 OpenAI 兼容接口，
把用户输入的自然语言记账文本解析为 `{amount, category, note}` 结构，
并用 Redis 保存最近 6 轮对话作为上下文。

## 已知限制

- **没有数据库建表脚本**。表结构依赖 MyBatis-Plus 注解与 `@Select` 中的裸 SQL，
  克隆仓库后无法直接跑起来，需要自行建表。
- **没有自动化测试**。`backend/src/test` 下只有 Spring Boot 生成的空上下文测试。
- **登录态是 UUID token + Redis Hash，不是 JWT**。项目未使用 Spring Security，
  鉴权由两个 `HandlerInterceptor` 手工实现，涉及资源归属的接口需自行校验 `userId`。
- **`ai-server` 无鉴权**且 CORS 允许任意来源，仅适合本地开发，不应直接暴露到公网。
- HarmonyOS 客户端部分入口（如任务列表）后端尚未实现。
