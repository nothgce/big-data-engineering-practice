# 环境部署文档

## 项目简介

UserActionAnalyzePlatform 是一个基于 Apache Spark 的电商用户行为分析平台，在 Docker 容器中以 Local 模式运行 Spark，分析结果写入 MySQL。

---

## 一、环境要求

| 组件 | 版本要求 | 说明 |
|------|----------|------|
| JDK | 8 | Maven 编译和 IDE 运行均需 Java 8 |
| Maven | 3.6+ | 用于编译打包 |
| Docker Desktop | 最新稳定版 | 运行 MySQL 和 Spark 容器 |
| 操作系统 | Windows 10/11 | 已验证；Linux/macOS 同样支持 |

### 检查环境

```bash
java -version     # 应输出 1.8.x
mvn -version      # 应输出 3.x.x
docker version    # 应输出 Client/Server 信息
```

---

## 二、一键部署（推荐）

项目提供了自动化部署脚本，执行以下步骤即可完成所有操作：

```bat
deploy\build-and-run.bat
```

脚本会自动完成：
1. 检查 Docker 和 Maven 是否可用
2. Maven 编译打包（`mvn clean package -DskipTests`）
3. 启动 MySQL 容器并等待健康检查通过
4. 构建 Spark 镜像并运行分析任务
5. 查询 MySQL 打印分析结果

首次运行需要下载 Maven 依赖和 Docker 镜像，耗时较长（5~15 分钟），后续运行约 1~2 分钟。

---

## 三、手动部署步骤

### 3.1 编译打包

```bash
mvn clean package -DskipTests
```

产物路径：
```
target/UserActionAnalyzePlatform-1.0-SNAPSHOT-jar-with-dependencies.jar
```

### 3.2 启动 MySQL

```bash
docker-compose up -d mysql
```

等待 MySQL 就绪（healthy 状态）：

```bash
docker ps
# 看到 useranalyze-mysql 状态为 (healthy) 即可继续
```

### 3.3 运行 Spark 任务

```bash
docker-compose up --build spark-app
```

Spark 容器执行完毕后自动退出（exit code 0 为成功）。

### 3.4 停止所有容器

```bash
docker-compose down
```

停止并删除数据卷（清空 MySQL 数据）：

```bash
docker-compose down -v
```

---

## 四、项目结构

```
UserActionAnalyzePlatform-master/
├── src/main/
│   ├── java/cn/edu/hust/
│   │   ├── session/         # 主程序（UserVisitAnalyze.java）
│   │   ├── dao/             # 数据访问层
│   │   ├── domain/          # 数据模型
│   │   ├── jdbc/            # JDBC 连接池
│   │   ├── mockData/        # 模拟数据生成
│   │   ├── util/            # 工具类
│   │   └── conf/            # 配置管理
│   └── resources/
│       └── conf.properties  # 数据库和 Spark 配置
├── deploy/
│   ├── init.sql             # MySQL 建库建表脚本
│   ├── build-and-run.bat    # 一键部署脚本
│   ├── install-maven.ps1    # Maven 安装脚本
│   └── fix-java-home.ps1    # JAVA_HOME 修复脚本
├── docker-compose.yml       # 容器编排配置
├── Dockerfile               # Spark 应用镜像定义
└── pom.xml                  # Maven 构建配置
```

---

## 五、配置说明

### 5.1 数据库配置（`src/main/resources/conf.properties`）

```properties
jdbc.driver=com.mysql.jdbc.Driver
jdbc.url=jdbc:mysql://mysql:3306/BigDataPlatm?useUnicode=true&characterEncoding=UTF-8
jdbc.username=root
jdbc.password=root
jdbc.active=20       # 连接池大小
spark.local=true     # 以 Local 模式运行 Spark
```

> **注意**：`jdbc.url` 中的 `mysql` 是 Docker Compose 服务名。若在容器外直接运行 JAR，需改为 `localhost`。

### 5.2 MySQL 连接信息

| 参数 | 值 |
|------|----|
| Host | localhost |
| Port | 3306 |
| Database | BigDataPlatm |
| Username | root |
| Password | root |

### 5.3 Spark 资源配置（`docker-compose.yml`）

```yaml
environment:
  JAVA_TOOL_OPTIONS: "-Xmx2g -Xms512m"
```

如需修改内存，编辑 `docker-compose.yml` 中的 `JAVA_TOOL_OPTIONS`。

---

## 六、数据库表结构

| 表名 | 说明 |
|------|------|
| `task` | 分析任务配置表 |
| `session_aggr_stat` | Session 聚合统计结果（访问时长/步长分布） |
| `session_random_extract` | 随机抽取的 Session 样本 |
| `session_detail` | Session 行为明细 |
| `top10_category` | Top10 热门品类（点击/下单/支付） |
| `top10_category_session` | Top10 品类下的 Top10 Session |

---

## 七、常见问题

### Maven 编译报错：Source option 6 is no longer supported

`pom.xml` 中编译版本已设置为 1.8，请确认使用的是 JDK 8+：

```bash
echo %JAVA_HOME%
java -version
```

如 `JAVA_HOME` 未设置，运行 `deploy\fix-java-home.ps1` 自动修复。

### Maven 未找到

运行 PowerShell 脚本自动安装：

```powershell
deploy\install-maven.ps1
```

### Docker 容器无法启动

确认 Docker Desktop 已启动并处于运行状态（系统托盘图标为绿色）。

### Spark 容器立即退出

查看日志排查原因：

```bash
docker-compose logs spark-app
```
