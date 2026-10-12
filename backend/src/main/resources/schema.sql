-- Coin Shell 数据库结构
--
-- 用法：
--   mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS \`coin-shell\` DEFAULT CHARACTER SET utf8mb4"
--   mysql -u root -p coin-shell < schema.sql
--
-- 说明：本脚本按 entity/po 下的实体类与 mapper 中的裸 SQL 反推而来。
-- 其中的唯一索引是 FlashGrabServiceImpl 做并发兜底时依赖的，不要删除。

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- 用户
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `user` (
  `id`       BIGINT       NOT NULL AUTO_INCREMENT,
  `phone`    VARCHAR(20)  NOT NULL COMMENT '手机号，登录账号',
  `username` VARCHAR(64)  NOT NULL COMMENT '昵称',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户';

-- ---------------------------------------------------------------------------
-- 用户资产（与 user 一对一，user_id 即主键）
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `user_coin` (
  `user_id`              BIGINT        NOT NULL COMMENT '用户ID',
  `coin_balance`         INT           NOT NULL DEFAULT 0 COMMENT '金币余额',
  `cash_balance`         DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '现金余额',
  `total_earned_coin`    INT           NOT NULL DEFAULT 0 COMMENT '累计获得金币',
  `total_withdrawn_cash` DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '累计提现现金',
  `updated_at`           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户资产';

-- ---------------------------------------------------------------------------
-- 签到记录
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sign_record` (
  `id`          BIGINT   NOT NULL AUTO_INCREMENT,
  `user_id`     BIGINT   NOT NULL,
  `sign_date`   DATE     NOT NULL COMMENT '签到日期',
  `coin_gained` INT      NOT NULL DEFAULT 0 COMMENT '本次获得金币',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  -- 同一用户同一天只能签到一次
  UNIQUE KEY `uk_sign_user_date` (`user_id`, `sign_date`),
  -- getConsecutiveSignDays 的窗口函数按 user_id 过滤、sign_date 排序
  KEY `idx_sign_user_date` (`user_id`, `sign_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='签到记录';

-- ---------------------------------------------------------------------------
-- 限时抢购活动配置
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `flash_activity_config` (
  `id`             BIGINT      NOT NULL AUTO_INCREMENT,
  `activity_name`  VARCHAR(128) NOT NULL COMMENT '活动名称',
  `start_time`     TIME        NOT NULL COMMENT '每日开始时间',
  `end_time`       TIME        NOT NULL COMMENT '每日结束时间',
  `total_quota`    INT         NOT NULL DEFAULT 0 COMMENT '每日总名额',
  `coin_amount`    INT         NOT NULL DEFAULT 0 COMMENT '单次获得金币',
  `per_user_limit` INT         NOT NULL DEFAULT 1 COMMENT '每人可领取次数',
  `is_active`      TINYINT(1)  NOT NULL DEFAULT 1 COMMENT '是否启用',
  `create_time`    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time`    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  -- getActiveActivity: WHERE is_active = 1 ORDER BY id DESC LIMIT 1
  KEY `idx_flash_active` (`is_active`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='限时抢购活动配置';

-- ---------------------------------------------------------------------------
-- 抢购领取记录
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `flash_grab_record` (
  `id`          BIGINT   NOT NULL AUTO_INCREMENT,
  `user_id`     BIGINT   NOT NULL,
  `activity_id` BIGINT   NOT NULL,
  `grab_date`   DATE     NOT NULL COMMENT '领取日期',
  `coin_gained` INT      NOT NULL DEFAULT 0,
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  -- 关键：FlashGrabServiceImpl 捕获 DuplicateKeyException 依赖此唯一约束兜底防重复发放
  UNIQUE KEY `uk_grab_user_activity_date` (`user_id`, `activity_id`, `grab_date`),
  KEY `idx_grab_activity_date` (`activity_id`, `grab_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='抢购领取记录';

-- ---------------------------------------------------------------------------
-- 金币兑换规则
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `exchange_rule` (
  `id`         INT           NOT NULL AUTO_INCREMENT,
  `coin_rate`  INT           NOT NULL COMMENT '多少金币',
  `cash_rate`  DECIMAL(12,2) NOT NULL COMMENT '兑换多少现金',
  `min_cash`   DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '单次最小兑换额',
  `max_cash`   DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '单次最大兑换额',
  `daily_limit` DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '每日兑换上限',
  `is_active`  TINYINT(1)    NOT NULL DEFAULT 1,
  `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_exchange_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='金币兑换规则';

-- ---------------------------------------------------------------------------
-- 收益流水（资产变动全部走这张表，便于审计与统计聚合）
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `earnings_detail` (
  `id`            BIGINT        NOT NULL AUTO_INCREMENT,
  `user_id`       BIGINT        NOT NULL,
  `asset_type`    VARCHAR(16)   NOT NULL COMMENT '资产类型：coin / cash',
  `change_type`   VARCHAR(32)   NOT NULL COMMENT '变动类型：sign / flash / exchange 等',
  `amount`        DECIMAL(12,2) NOT NULL COMMENT '变动金额（正数）',
  `balance_after` DECIMAL(12,2) NOT NULL COMMENT '变动后余额',
  `source_id`     BIGINT        NULL COMMENT '来源业务记录ID',
  `source_type`   VARCHAR(32)   NULL COMMENT '来源业务类型',
  `description`   VARCHAR(255)  NULL,
  `create_time`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_earnings_user_time` (`user_id`, `create_time`),
  KEY `idx_earnings_user_type` (`user_id`, `change_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='收益流水';

-- ---------------------------------------------------------------------------
-- 记账记录（由 ai-server 解析自然语言后写入）
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `account` (
  `id`           BIGINT        NOT NULL AUTO_INCREMENT,
  `user_id`      BIGINT        NOT NULL,
  `amount`       DECIMAL(12,2) NOT NULL,
  `type`         INT           NOT NULL DEFAULT 2 COMMENT '1=收入 2=支出',
  `category`     VARCHAR(32)   NOT NULL DEFAULT '其他',
  `note`         VARCHAR(255)  NULL,
  `account_time` DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_account_user_time` (`user_id`, `account_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='记账记录';

-- ---------------------------------------------------------------------------
-- 初始化一条抢购活动配置（可选，便于本地跑通）
-- ---------------------------------------------------------------------------
INSERT INTO `flash_activity_config`
  (`activity_name`, `start_time`, `end_time`, `total_quota`, `coin_amount`, `per_user_limit`, `is_active`)
SELECT '每日限时领金币', '10:00:00', '23:59:00', 1000, 100, 1, 1
WHERE NOT EXISTS (SELECT 1 FROM `flash_activity_config`);

-- 初始化一条兑换规则：100 金币 = 1 元，单次 1~50 元
INSERT INTO `exchange_rule`
  (`coin_rate`, `cash_rate`, `min_cash`, `max_cash`, `daily_limit`, `is_active`)
SELECT 100, 1.00, 1.00, 50.00, 100.00, 1
WHERE NOT EXISTS (SELECT 1 FROM `exchange_rule`);
