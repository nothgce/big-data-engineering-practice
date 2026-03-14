# 使用文档

## 一、快速开始

### 运行分析任务

```bash
# 首次运行（编译 + 启动 MySQL + 运行 Spark）
deploy\build-and-run.bat

# 后续重新运行 Spark 任务（无需重新编译）
docker-compose up spark-app

# 仅重新编译并运行
deploy\build-and-run.bat
```

### 查看分析结果

```bash
# 查看所有结果表
docker-compose exec mysql mysql -uroot -proot BigDataPlatm -e "
  SELECT * FROM session_aggr_stat;
  SELECT * FROM session_random_extract LIMIT 10;
  SELECT * FROM top10_category;
  SELECT * FROM top10_category_session;
  SELECT * FROM session_detail LIMIT 10;
"
```

---

## 二、分析任务说明

### 任务配置

分析任务存储在 MySQL `task` 表中，通过 `task_id` 指定要运行的任务。

当前预置任务（`task_id=1`）：

```json
{
  "startDate": "2010-01-01",
  "endDate":   "2030-12-31",
  "startAge":  "1",
  "endAge":    "100"
}
```

此配置为宽松条件，会处理所有模拟生成的用户行为数据。

### 自定义分析条件

向 `task` 表插入新任务，修改筛选条件：

```sql
INSERT INTO task (task_name, create_time, task_type, task_status, task_param)
VALUES (
  'my_analysis',
  NOW(),
  'session',
  'created',
  '{"startDate":"2026-01-01","endDate":"2026-12-31","startAge":"18","endAge":"35"}'
);
```

支持的筛选参数：

| 参数 | 说明 | 示例 |
|------|------|------|
| `startDate` | 行为数据开始日期 | `"2026-01-01"` |
| `endDate` | 行为数据结束日期 | `"2026-12-31"` |
| `startAge` | 用户年龄下限 | `"18"` |
| `endAge` | 用户年龄上限 | `"35"` |

### 运行指定任务

```bash
# 运行 task_id=2 的任务
docker-compose run --rm spark-app 2
```

---

## 三、分析结果说明

### 3.1 Session 聚合统计（`session_aggr_stat`）

统计符合条件的 Session 总数及其分布比例。

```sql
SELECT * FROM session_aggr_stat WHERE task_id = 1;
```

| 字段 | 说明 |
|------|------|
| `session_count` | 符合条件的 Session 总数 |
| `1s_3s` ~ `30m` | 各访问时长区间的 Session 占比 |
| `1_3` ~ `60` | 各访问步长（页面数）区间的 Session 占比 |

**访问时长区间：**

| 字段 | 时长范围 |
|------|----------|
| `1s_3s` | 1~3 秒 |
| `4s_6s` | 4~6 秒 |
| `7s_9s` | 7~9 秒 |
| `10s_30s` | 10~30 秒 |
| `30s_60s` | 30~60 秒 |
| `1m_3m` | 1~3 分钟 |
| `3m_10m` | 3~10 分钟 |
| `10m_30m` | 10~30 分钟 |
| `30m` | 30 分钟以上 |

**访问步长区间（浏览页面数）：**

| 字段 | 步长范围 |
|------|----------|
| `1_3` | 1~3 页 |
| `4_6` | 4~6 页 |
| `7_9` | 7~9 页 |
| `10_30` | 10~30 页 |
| `30_60` | 30~60 页 |
| `60` | 60 页以上 |

---

### 3.2 随机抽取 Session（`session_random_extract`）

从每个时间段随机均匀抽取的 Session 样本，用于人工审查。

```sql
SELECT * FROM session_random_extract WHERE task_id = 1;
```

| 字段 | 说明 |
|------|------|
| `session_id` | Session 唯一标识 |
| `start_time` | Session 开始时间 |
| `search_keywords` | 本次 Session 的搜索关键词 |

---

### 3.3 Top10 热门品类（`top10_category`）

按照点击数 → 下单数 → 支付数的优先级排序，统计最热门的 10 个商品品类。

```sql
SELECT * FROM top10_category WHERE task_id = 1 ORDER BY click_count DESC;
```

| 字段 | 说明 |
|------|------|
| `category_id` | 品类 ID |
| `click_count` | 点击次数 |
| `order_count` | 下单次数 |
| `pay_count` | 支付次数 |

---

### 3.4 Top10 品类的 Top10 Session（`top10_category_session`）

对每个 Top10 品类，找出点击该品类次数最多的 Top10 Session。

```sql
SELECT * FROM top10_category_session WHERE task_id = 1 ORDER BY category_id, click_count DESC;
```

| 字段 | 说明 |
|------|------|
| `category_id` | 品类 ID |
| `session_id` | Session 唯一标识 |
| `click_count` | 该 Session 点击此品类的次数 |

---

### 3.5 Session 行为明细（`session_detail`）

符合过滤条件的 Session 的完整行为记录。

```sql
SELECT * FROM session_detail WHERE task_id = 1 LIMIT 20;
```

| 字段 | 说明 |
|------|------|
| `user_id` | 用户 ID |
| `session_id` | Session ID |
| `page_id` | 访问页面 ID |
| `action_time` | 行为发生时间 |
| `search_keyword` | 搜索关键词（搜索行为时有值） |
| `click_category_id` | 点击的品类 ID |
| `click_product_id` | 点击的商品 ID |
| `order_category_ids` | 下单的品类 ID 列表 |
| `order_product_ids` | 下单的商品 ID 列表 |
| `pay_category_ids` | 支付的品类 ID 列表 |
| `pay_product_ids` | 支付的商品 ID 列表 |

---

## 四、常用命令

### 容器管理

```bash
# 查看运行中的容器
docker ps

# 查看 Spark 任务日志
docker-compose logs spark-app

# 实时跟踪日志
docker-compose logs -f spark-app

# 停止所有容器（保留数据）
docker-compose down

# 停止并清空数据库数据
docker-compose down -v

# 仅停止 MySQL
docker-compose stop mysql
```

### 数据库操作

```bash
# 进入 MySQL 交互终端
docker-compose exec mysql mysql -uroot -proot BigDataPlatm

# 查看所有结果表
docker-compose exec mysql mysql -uroot -proot BigDataPlatm -e "SHOW TABLES;"

# 清空结果表（下次运行前重置）
docker-compose exec mysql mysql -uroot -proot BigDataPlatm -e "
  TRUNCATE TABLE session_aggr_stat;
  TRUNCATE TABLE session_random_extract;
  TRUNCATE TABLE session_detail;
  TRUNCATE TABLE top10_category;
  TRUNCATE TABLE top10_category_session;
"
```

### 重新构建镜像

```bash
# 代码修改后重新编译并重建镜像
mvn clean package -DskipTests
docker-compose build spark-app
docker-compose up spark-app
```

---

## 五、使用 Navicat / DBeaver 连接数据库

| 参数 | 值 |
|------|----|
| 连接类型 | MySQL |
| Host | localhost |
| Port | 3306 |
| 数据库 | BigDataPlatm |
| 用户名 | root |
| 密码 | root |

连接后可在 GUI 中直接浏览和查询各结果表。

---

## 六、数据流说明

```
MockData（模拟生成用户行为数据）
    │
    ▼
Spark RDD 按日期/年龄等条件过滤
    │
    ▼
按 Session 聚合 → 统计访问时长/步长分布
    │
    ├──→ session_aggr_stat（聚合统计）
    ├──→ session_random_extract（随机抽取样本）
    ├──→ session_detail（明细数据）
    ├──→ top10_category（热门品类排行）
    └──→ top10_category_session（品类下的热门 Session）
```
