const mysql = require('mysql2');

const db = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'fitaura_db'
});

const createPromotions = `
CREATE TABLE IF NOT EXISTS \`promotions\` (
  \`promotion_id\` int NOT NULL AUTO_INCREMENT,
  \`store_id\` int NOT NULL,
  \`title\` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  \`discount\` int NOT NULL,
  \`start_date\` date NOT NULL,
  \`end_date\` date NOT NULL,
  \`status\` int NOT NULL DEFAULT '1',
  \`created_at\` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (\`promotion_id\`),
  KEY \`store_id\` (\`store_id\`),
  CONSTRAINT \`promotions_ibfk_1\` FOREIGN KEY (\`store_id\`) REFERENCES \`store\` (\`store_id\`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
`;

const createPromotionProducts = `
CREATE TABLE IF NOT EXISTS \`promotion_products\` (
  \`promotion_id\` int NOT NULL,
  \`product_id\` int NOT NULL,
  PRIMARY KEY (\`promotion_id\`, \`product_id\`),
  KEY \`product_id\` (\`product_id\`),
  CONSTRAINT \`promotion_products_ibfk_1\` FOREIGN KEY (\`promotion_id\`) REFERENCES \`promotions\` (\`promotion_id\`) ON DELETE CASCADE,
  CONSTRAINT \`promotion_products_ibfk_2\` FOREIGN KEY (\`product_id\`) REFERENCES \`products\` (\`product_id\`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
`;

function createTables() {
  db.query(createPromotions, (err, results) => {
    if (err) {
      console.error("Error creating promotions:", err);
      process.exit(1);
    }
    console.log("Promotions table created/verified.");
    db.query(createPromotionProducts, (err, results) => {
      if (err) {
        console.error("Error creating promotion_products:", err);
        process.exit(1);
      }
      console.log("Promotion_products table created/verified.");
      process.exit(0);
    });
  });
}

// Migration logic: Check if promotions table exists, and if so check if status column is present
db.query("SHOW COLUMNS FROM `promotions` LIKE 'status'", (err, rows) => {
  if (err) {
    // Table might not exist yet, let createTables handle it
    createTables();
  } else if (rows.length === 0) {
    // Table exists but status column is missing
    console.log("Migrating database: Adding status column to promotions table...");
    db.query("ALTER TABLE `promotions` ADD COLUMN `status` INT DEFAULT 1", (err) => {
      if (err) {
        console.error("Error adding status column during migration:", err);
        process.exit(1);
      }
      console.log("Migration successful: status column added.");
      createTables();
    });
  } else {
    // Column already exists
    createTables();
  }
});
