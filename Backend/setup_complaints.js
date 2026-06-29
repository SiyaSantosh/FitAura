const mysql = require('mysql2');

const db = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'fitaura_db'
});

const query = `
CREATE TABLE IF NOT EXISTS \`complaints\` (
  \`complaint_id\` INT NOT NULL AUTO_INCREMENT,
  \`order_id\` INT NOT NULL,
  \`product_id\` INT NOT NULL,
  \`store_id\` INT NOT NULL,
  \`user_id\` INT NOT NULL,
  \`status\` VARCHAR(20) DEFAULT 'review',
  \`type\` VARCHAR(20) NOT NULL,
  \`issue\` VARCHAR(50) NOT NULL,
  \`description\` TEXT NOT NULL,
  \`images\` LONGTEXT,
  \`admin_decision\` VARCHAR(30) DEFAULT NULL,
  \`admin_verification\` VARCHAR(50) DEFAULT NULL,
  \`admin_comment\` TEXT DEFAULT NULL,
  \`refund_amount\` DECIMAL(10, 2) DEFAULT 0.00,
  \`created_at\` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (\`complaint_id\`),
  CONSTRAINT \`complaints_ibfk_1\` FOREIGN KEY (\`order_id\`) REFERENCES \`orders\` (\`order_id\`) ON DELETE CASCADE,
  CONSTRAINT \`complaints_ibfk_2\` FOREIGN KEY (\`product_id\`) REFERENCES \`products\` (\`product_id\`) ON DELETE CASCADE,
  CONSTRAINT \`complaints_ibfk_3\` FOREIGN KEY (\`store_id\`) REFERENCES \`store\` (\`store_id\`) ON DELETE CASCADE,
  CONSTRAINT \`complaints_ibfk_4\` FOREIGN KEY (\`user_id\`) REFERENCES \`users\` (\`user_id\`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
`;

db.query(query, (err, results) => {
  if (err) {
    console.error("Error creating complaints table:", err);
    process.exit(1);
  }
  console.log("Complaints table successfully created/verified.");
  process.exit(0);
});
