-- ============================================
-- UserActionAnalyzePlatform 数据库初始化脚本
-- ============================================

CREATE DATABASE IF NOT EXISTS BigDataPlatm DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE BigDataPlatm;

-- 任务表：存储 J2EE 平台提交的分析任务
CREATE TABLE IF NOT EXISTS `task` (
  `task_id`     int(11)      NOT NULL AUTO_INCREMENT,
  `task_name`   varchar(255) DEFAULT NULL,
  `create_time` varchar(255) DEFAULT NULL,
  `start_time`  varchar(255) DEFAULT NULL,
  `finish_time` varchar(255) DEFAULT NULL,
  `task_type`   varchar(255) DEFAULT NULL,
  `task_status` varchar(255) DEFAULT NULL,
  `task_param`  text,
  PRIMARY KEY (`task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

-- session 聚合统计结果表
CREATE TABLE IF NOT EXISTS `session_aggr_stat` (
  `task_id`       int(11) NOT NULL,
  `session_count` int(11) DEFAULT NULL,
  `1s_3s`         double  DEFAULT NULL,
  `4s_6s`         double  DEFAULT NULL,
  `7s_9s`         double  DEFAULT NULL,
  `10s_30s`       double  DEFAULT NULL,
  `30s_60s`       double  DEFAULT NULL,
  `1m_3m`         double  DEFAULT NULL,
  `3m_10m`        double  DEFAULT NULL,
  `10m_30m`       double  DEFAULT NULL,
  `30m`           double  DEFAULT NULL,
  `1_3`           double  DEFAULT NULL,
  `4_6`           double  DEFAULT NULL,
  `7_9`           double  DEFAULT NULL,
  `10_30`         double  DEFAULT NULL,
  `30_60`         double  DEFAULT NULL,
  `60`            double  DEFAULT NULL,
  PRIMARY KEY (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 随机抽取 session 结果表
CREATE TABLE IF NOT EXISTS `session_random_extract` (
  `task_id`         int(11)      NOT NULL,
  `session_id`      varchar(255) DEFAULT NULL,
  `start_time`      varchar(50)  DEFAULT NULL,
  `end_time`        varchar(50)  DEFAULT NULL,
  `search_keywords` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Top10 品类统计结果表
CREATE TABLE IF NOT EXISTS `top10_category` (
  `task_id`     int(11) NOT NULL,
  `category_id` int(11) DEFAULT NULL,
  `click_count` int(11) DEFAULT NULL,
  `order_count` int(11) DEFAULT NULL,
  `pay_count`   int(11) DEFAULT NULL,
  PRIMARY KEY (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Top10 品类下 Top10 Session 结果表
CREATE TABLE IF NOT EXISTS `top10_category_session` (
  `task_id`     int(11)      NOT NULL,
  `category_id` int(11)      DEFAULT NULL,
  `session_id`  varchar(255) DEFAULT NULL,
  `click_count` int(11)      DEFAULT NULL,
  PRIMARY KEY (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Session 明细数据表
CREATE TABLE IF NOT EXISTS `session_detail` (
  `task_id`           int(11)      NOT NULL,
  `user_id`           int(11)      DEFAULT NULL,
  `session_id`        varchar(255) DEFAULT NULL,
  `page_id`           int(11)      DEFAULT NULL,
  `action_time`       varchar(255) DEFAULT NULL,
  `search_keyword`    varchar(255) DEFAULT NULL,
  `click_category_id` int(11)      DEFAULT NULL,
  `click_product_id`  int(11)      DEFAULT NULL,
  `order_category_ids` varchar(255) DEFAULT NULL,
  `order_product_ids` varchar(255) DEFAULT NULL,
  `pay_category_ids`  varchar(255) DEFAULT NULL,
  `pay_product_ids`   varchar(255) DEFAULT NULL,
  PRIMARY KEY (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ============================================
-- 初始化测试任务（task_id=1，宽条件保证有数据通过）
-- ============================================
INSERT INTO `task` (
  `task_id`, `task_name`, `create_time`, `task_type`, `task_status`, `task_param`
) VALUES (
  1,
  'session_analysis_demo',
  '2026-03-14 00:00:00',
  'session',
  'created',
  '{"startDate":"2010-01-01","endDate":"2030-12-31","startAge":"1","endAge":"100"}'
);
