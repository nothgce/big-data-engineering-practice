# ============================================================
# UserActionAnalyzePlatform - 多阶段构建
# Stage 1: Maven + JDK 8 编译打包
# Stage 2: JRE 8 运行
# 无需主机安装 JDK 或 Maven
# ============================================================

# ---- Stage 1: Build ----
FROM maven:3.9-eclipse-temurin-8 AS builder

WORKDIR /build

# 先拷贝 pom.xml，单独下载依赖（利用 Docker 层缓存，依赖不变时跳过下载）
COPY pom.xml .
RUN mvn dependency:go-offline -B

# 再拷贝源码并编译
COPY src/ src/
RUN mvn clean package -DskipTests -B

# ---- Stage 2: Run ----
FROM eclipse-temurin:8-jre-jammy

LABEL maintainer="course-group"
LABEL description="电商用户行为分析大数据平台 - Spark Local Mode"

WORKDIR /app

COPY --from=builder /build/target/UserActionAnalyzePlatform-1.0-SNAPSHOT-jar-with-dependencies.jar app.jar

ENTRYPOINT ["java", \
            "-Xmx2g", \
            "-Xms512m", \
            "-cp", "app.jar", \
            "cn.edu.hust.session.UserVisitAnalyze"]

CMD ["1"]
