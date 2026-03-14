# ============================================================
# UserActionAnalyzePlatform - Spark Local Mode Docker 镜像
# 基础镜像：OpenJDK 8（与 Spark 1.5.1 / Scala 2.10 兼容）
# ============================================================
FROM eclipse-temurin:8-jre-jammy

LABEL maintainer="course-group"
LABEL description="电商用户行为分析大数据平台 - Spark Local Mode"

WORKDIR /app

# 拷贝 Maven 打包产生的 fat JAR
COPY target/UserActionAnalyzePlatform-1.0-SNAPSHOT-jar-with-dependencies.jar app.jar

# 默认以 task_id=1 运行；可在 docker run 时覆盖 CMD 参数
ENTRYPOINT ["java", \
            "-Xmx2g", \
            "-Xms512m", \
            "-cp", "app.jar", \
            "cn.edu.hust.session.UserVisitAnalyze"]

CMD ["1"]
