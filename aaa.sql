DROP DATABASE IF EXISTS monthly_land_installments;
CREATE DATABASE monthly_land_installments
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE monthly_land_installments;

SET GLOBAL event_scheduler = ON;

  

    -- ════════════════════════════════════════════════════════════════════
-- TABLE: monthly_land_installments
-- Tracks each monthly installment payment per client, plot, and sale
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE monthly_land_installments (
  installment_id     INT            NOT NULL AUTO_INCREMENT,
  sales_month        VARCHAR(7)     NOT NULL               COMMENT 'YYYY-MM format e.g. 2025-01',
  period_start       DATE           NOT NULL,
  period_end         DATE           NOT NULL,
  sale_id            VARCHAR(30)    NOT NULL               COMMENT 'FK → transactions.tx_id',
  plot_id            VARCHAR(20)    NOT NULL               COMMENT 'FK → parcels.parcel_id',
  client_id          INT            NOT NULL               COMMENT 'FK → clients.client_id',
  staff_id           INT            NOT NULL               COMMENT 'FK → agents.agent_id — staff who processed this installment',
  installment_no     INT            NOT NULL DEFAULT 1     COMMENT 'Which installment number in the repayment schedule e.g. 1,2,3',
  total_price        DECIMAL(15,2)  NOT NULL DEFAULT 0     COMMENT 'Total agreed sale price of the plot',
  installment_amount DECIMAL(15,2)  NOT NULL DEFAULT 0     COMMENT 'Amount due this month',
  amount_paid        DECIMAL(15,2)  NOT NULL DEFAULT 0     COMMENT 'Amount actually received this month',
  balance_remaining  DECIMAL(15,2)  NOT NULL DEFAULT 0     COMMENT 'Outstanding balance after this payment',
  due_date           DATE           NOT NULL               COMMENT 'Date this installment is due',
  paid_date          DATE           DEFAULT NULL           COMMENT 'Date payment was received, NULL if unpaid',
  payment_method     ENUM('Cash','Bank Transfer','Mobile Money','Cheque') NOT NULL DEFAULT 'Bank Transfer',
  status             ENUM('Pending','Paid','Overdue','Partially Paid','Cancelled') NOT NULL DEFAULT 'Pending',
  is_open            TINYINT(1)     NOT NULL DEFAULT 1     COMMENT '1=open/active, 0=closed/finalized',
  notes              TEXT           DEFAULT NULL,
  created_at         DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at         DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (installment_id),
  CONSTRAINT fk_inst_plot   FOREIGN KEY (plot_id)   REFERENCES parcels(parcel_id)               ON UPDATE CASCADE,
  CONSTRAINT fk_inst_client FOREIGN KEY (client_id) REFERENCES clients(client_id)               ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_inst_staff  FOREIGN KEY (staff_id)  REFERENCES agents(agent_id)                 ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Monthly land installment payment schedule per client and plot';


-- ════════════════════════════════════════════════════════════════════
-- TABLE: installment_notifications
-- Notifications tied to each monthly installment record
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE installment_notifications (
  notification_id    INT            NOT NULL AUTO_INCREMENT,
  installment_id     INT            NOT NULL               COMMENT 'FK → monthly_land_installments.installment_id',
  notification_type  ENUM('Due Reminder','Overdue Alert','Payment Confirmed','Partial Payment','Cancelled') NOT NULL,
  channel            ENUM('SMS','Email','WhatsApp','System') NOT NULL DEFAULT 'SMS',
  client_id       INT            NOT NULL               COMMENT 'FK → clients.client_id — who receives this notification',
  sent_by            INT            DEFAULT NULL           COMMENT 'FK → agents.agent_id — staff who triggered it, NULL if system-generated',
  message            TEXT           NOT NULL               COMMENT 'Notification message content',
  is_sent            TINYINT(1)     NOT NULL DEFAULT 0     COMMENT '1=sent successfully, 0=pending/failed',
  sent_at            DATETIME       DEFAULT NULL           COMMENT 'Timestamp when notification was dispatched',
  read_at            DATETIME       DEFAULT NULL           COMMENT 'Timestamp when client acknowledged/read it',
  created_at         DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (notification_id),
  CONSTRAINT fk_notif_installment FOREIGN KEY (installment_id) REFERENCES monthly_land_installments(installment_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_notif_client   FOREIGN KEY (client_id)   REFERENCES clients(client_id)                        ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_notif_staff       FOREIGN KEY (sent_by)        REFERENCES agents(agent_id)                          ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Notifications sent per installment — due reminders, overdue alerts, confirmations';  