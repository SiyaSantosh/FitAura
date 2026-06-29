const mysql = require('mysql2');

const db = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'fitaura_db'
});

const walletQuery = `
CREATE TABLE IF NOT EXISTS \`wallet\` (
  \`wallet_id\` INT NOT NULL AUTO_INCREMENT,
  \`user_id\` INT NOT NULL,
  \`balance\` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (\`wallet_id\`),
  UNIQUE KEY \`wallet_user_unique\` (\`user_id\`),
  CONSTRAINT \`wallet_user_fk\` FOREIGN KEY (\`user_id\`) REFERENCES \`users\` (\`user_id\`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
`;

const walletStoreCreditQuery = `
CREATE TABLE IF NOT EXISTS \`wallet_store_credit\` (
  \`wallet_store_credit_id\` INT NOT NULL AUTO_INCREMENT,
  \`user_id\` INT NOT NULL,
  \`store_id\` INT NOT NULL,
  \`balance\` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (\`wallet_store_credit_id\`),
  UNIQUE KEY \`wallet_store_credit_unique\` (\`user_id\`, \`store_id\`),
  CONSTRAINT \`wallet_store_credit_user_fk\` FOREIGN KEY (\`user_id\`) REFERENCES \`users\` (\`user_id\`) ON DELETE CASCADE,
  CONSTRAINT \`wallet_store_credit_store_fk\` FOREIGN KEY (\`store_id\`) REFERENCES \`store\` (\`store_id\`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
`;

const orderColumnQuery = `
ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS wallet_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS cash_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00;
`;

db.query(walletQuery, (walletErr) => {
  if (walletErr) {
    console.error('Error creating wallet table:', walletErr);
    process.exit(1);
  }

  db.query(walletStoreCreditQuery, (storeCreditErr) => {
    if (storeCreditErr) {
      console.error('Error creating wallet_store_credit table:', storeCreditErr);
      process.exit(1);
    }
    console.log('Wallet and wallet_store_credit tables successfully created/verified.');
    process.exit(0);
  });
});
