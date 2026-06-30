const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const nodemailer = require('nodemailer');
const bcrypt = require('bcryptjs');

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));


// --- Http Server + Socket.Io Setup ---

const http = require('http');
const { Server } = require('socket.io');

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

const connectedUsers = {};

io.on('connection', (socket) => {

  socket.on('register', (userId) => {
    connectedUsers[String(userId)] = socket.id;
  });

  socket.on('send_message', (data) => {
    const { senderId, receiverId, message } = data;

    const sql = `INSERT INTO messages (sender_id, receiver_id, message) VALUES (?, ?, ?)`;
    db.query(sql, [senderId, receiverId, message], (err, result) => {
      if (err) {
        return;
      }

      const savedMessage = {
        message_id: result.insertId,
        sender_id: senderId,
        receiver_id: receiverId,
        message: message,
        created_at: new Date()
      };

      socket.emit('receive_message', savedMessage);

      const receiverSocketId = connectedUsers[String(receiverId)];
      if (receiverSocketId) {
        io.to(receiverSocketId).emit('receive_message', savedMessage);
      }
    });
  });

  socket.on('disconnect', () => {
    for (const [uid, sid] of Object.entries(connectedUsers)) {
      if (sid === socket.id) {
        delete connectedUsers[uid];
        break;
      }
    }
  });
});

// --- Database Connection ---
const db = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'fitaura_db'
});

db.query(
  `
    ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS wallet_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS cash_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00
  `,
  (err) => {
    if (err) {
      console.error('Error ensuring orders wallet/cash columns exist:', err);
    }
  }
);

// --- Helper: Save Notification To Db + Emit If User Is Online ---
const sendNotification = (userId, title, message) => {
  db.query(
    'INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)',
    [userId, title, message],
    (err, result) => {
      if (err) return;

    }
  );
};

const notifyAllAdmins = (title, message) => {
  db.query('SELECT user_id FROM users WHERE usertype_id = 3', (err, admins) => {
    if (err || !admins) return;
    admins.forEach(admin => sendNotification(admin.user_id, title, message));
  });
};

const getWishlistProductIdsByUser = (userId, callback) => {
  const sql = 'SELECT DISTINCT product_id FROM user_interactions WHERE user_id = ? AND interaction_type = ?';
  db.query(sql, [userId, 'wishlist'], (err, results) => {
    if (err) return callback(err, []);
    const productIds = results.map(row => row.product_id);
    callback(null, productIds);
  });
};

// Attaches promotion_discount to each product in `products` array
// by looking up active promotions from the DB.
const attachPromotionDiscounts = (products, callback) => {
  if (!products || products.length === 0) return callback(products);
  const ids = products.map(p => p.product_id).filter(Boolean);
  if (ids.length === 0) return callback(products);

  const sql = `
    SELECT pp.product_id, MAX(pr.discount) AS promotion_discount
    FROM promotion_products pp
    JOIN promotions pr ON pp.promotion_id = pr.promotion_id
    WHERE pp.product_id IN (?)
      AND pr.status = 1
      AND CURDATE() BETWEEN DATE(pr.start_date) AND DATE(pr.end_date)
    GROUP BY pp.product_id
  `;
  db.query(sql, [ids], (err, rows) => {
    if (err) return callback(products); // fail gracefully
    const discountMap = {};
    rows.forEach(row => { discountMap[row.product_id] = row.promotion_discount; });
    products.forEach(p => {
      p.promotion_discount = discountMap[p.product_id] ?? null;
    });
    callback(products);
  });
};


// --- Email Setup ---
const otpStore = {};
const pendingSignups = {};

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'siya.santosh.kumar@gmail.com',
    pass: 'aseg ebsx lbon rxzq'
  }
});

const generateOtp = () => Math.floor(100000 + Math.random() * 900000).toString();


// --- Sign Up ---
app.post('/api/users', (req, res) => {
  const { role, name, email, password } = req.body;

  db.query('SELECT user_id FROM users WHERE email = ?', [email], async (err, result) => {
    if (err) return res.status(500).json({ success: false, message: 'Database error' });
    if (result.length > 0) return res.status(409).json({ success: false, message: 'Email already exists' });

    const otp = generateOtp();
    otpStore[email] = { otp, expires: Date.now() + 5 * 60 * 1000 };
    pendingSignups[email] = { role: role.toLowerCase(), name, email, password };

    try {
      await transporter.sendMail({
        from: '"FitAura"',
        to: email,
        subject: 'Your OTP for FitAura',
        text: `Your OTP is: ${otp}`
      });
      res.status(200).json({ success: true });
    } catch (error) {
      res.status(500).json({ success: false, message: 'Error sending email' });
    }
  });
});

app.post('/api/users/verify_signup_otp', (req, res) => {
  const { email, otp } = req.body;
  const record = otpStore[email];
  const pendingUser = pendingSignups[email];

  if (record.expires < Date.now()) return res.status(400).json({ message: 'OTP expired' });
  if (record.otp !== otp) return res.status(400).json({ message: 'Incorrect OTP' });

  db.query('SELECT usertype_id FROM usertypes WHERE role = ?', [pendingUser.role], (err, roleResult) => {
    if (err || roleResult.length === 0) return res.status(404).json({ message: 'Role not found' });

    const typeId = roleResult[0].usertype_id;
    const hashedPassword = bcrypt.hashSync(pendingUser.password, 10);
    const hasAccess = typeId === 1 ? 1 : 0;

    const sql = 'INSERT INTO users (usertype_id, name, email, password, has_access) VALUES (?, ?, ?, ?, ?)';
    db.query(sql, [typeId, pendingUser.name, pendingUser.email, hashedPassword, hasAccess], (err, result) => {
      if (err) return res.status(500).json({ message: 'Failed to create user' });

      const walletSql = 'INSERT INTO wallet (user_id, balance) VALUES (?, 0.00)';
      db.query(walletSql, [result.insertId], (walletErr) => {
        if (walletErr) {
          console.error('Failed to create wallet for user', result.insertId, walletErr);
          return res.status(500).json({ message: 'Failed to create user wallet' });
        }

        delete otpStore[email];
        delete pendingSignups[email];

        if (hasAccess === 0) {
          notifyAllAdmins('New Account Request', `${pendingUser.name} has sent an account request`);
        }

        res.status(201).json({ success: true, user_id: result.insertId });
      });
    });
  });
});


// --- Update Profile ---
app.put('/api/users/:userId', (req, res) => {
  const { userId } = req.params;
  const { name, cnic, contact_number, address, gender, profile_picture } = req.body;

  const getUserSql = `
    SELECT u.*, ut.role 
    FROM users u 
    JOIN usertypes ut ON u.usertype_id = ut.usertype_id 
    WHERE u.user_id = ?
  `;

  db.query(getUserSql, [userId], (err, results) => {
    if (err || results.length === 0) return res.status(500).json({ success: false, message: 'User not found' });

    const user = results[0];
    const isSeller = user.role.toLowerCase() === 'seller';
    const triggerReverification = isSeller;

    const updateSql = `UPDATE users SET name=?, cnic=?, contact_number=?, address=?, gender=?, profile_picture=?, updated_at=NOW() ${triggerReverification ? ', has_access = 0' : ''} WHERE user_id=?`;

    db.query(updateSql, [name || user.name, cnic || user.cnic, contact_number || user.contact_number, address || user.address, gender || user.gender, profile_picture || user.profile_picture, userId], (err) => {
      if (err) return res.status(500).json({ success: false, message: 'Database error' });

      if (triggerReverification) {
        db.query('UPDATE store SET has_access = 0 WHERE owner_id = ?', [userId]);
        db.query(
          'UPDATE products SET is_visible = 2 WHERE is_active = 1 AND is_visible = 1 AND store_id IN (SELECT store_id FROM store WHERE owner_id = ?)',
          [userId]
        );

        notifyAllAdmins('Seller Profile Verification Required', `Seller "${name || user.name}" updated their profile. Re-verification required.`);
      }

      res.status(200).json({
        success: true,
        message: triggerReverification ? 'Profile updated and pending re-verification' : 'Profile updated successfully',
        requires_reverification: triggerReverification
      });
    });
  });
});


// --- Sign In ---
app.post('/api/users/signin', (req, res) => {
  const { email, password } = req.body;

  const sql = `SELECT * FROM users WHERE email = ?`;
  db.query(sql, [email], (err, users) => {
    if (err || users.length === 0) return res.status(401).json({ message: 'Invalid email or password' });

    const user = users[0];
    if (!bcrypt.compareSync(password, user.password)) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    db.query('SELECT role FROM usertypes WHERE usertype_id = ?', [user.usertype_id], (err, roles) => {
      const role = roles[0].role.toLowerCase();

      let profileDone = !!(user.contact_number && user.address && user.gender);
      if (role === 'seller' && !user.cnic) profileDone = false;

      if (role === 'seller') {
        if (!profileDone) {
          return res.json({ success: true, user_id: user.user_id, role, profile_completed: false });
        }

        db.query('SELECT * FROM store WHERE owner_id = ?', [user.user_id], (err, stores) => {
          const storeDone = stores.length > 0 && stores[0].store_name;
          if (!storeDone) {
            return res.json({ success: true, user_id: user.user_id, role, profile_completed: true, store_completed: false });
          }

          if (user.has_access !== 1) return res.status(403).json({ message: 'Account does not have access' });

          res.json({ success: true, user_id: user.user_id, name: user.name, email: user.email, role, profile_completed: true, store_completed: true });
        });
      } else {
        if (!profileDone) return res.json({ success: true, user_id: user.user_id, role, profile_completed: false });
        if (user.has_access !== 1) return res.status(403).json({ message: 'User does not have access' });

        res.json({ success: true, user_id: user.user_id, name: user.name, email: user.email, role, profile_completed: true, store_completed: true });
      }
    });
  });
});

const getSellerDeactivationEligibility = (userId, callback) => {
  const getUserSql = `
    SELECT u.user_id, u.name, u.deactivated, ut.role
    FROM users u
    JOIN usertypes ut ON u.usertype_id = ut.usertype_id
    WHERE u.user_id = ?
  `;

  db.query(getUserSql, [userId], (err, userRows) => {
    if (err) return callback(null, { success: false, message: 'Database error', error: err.message });
    if (userRows.length === 0) return callback(null, { success: false, message: 'User not found', status: 404 });

    const user = userRows[0];
    if (user.role?.toLowerCase() !== 'seller') {
      return callback(null, { success: false, message: 'Only sellers can use this endpoint', status: 400 });
    }
    if (user.deactivated === 1 || user.deactivated === '1' || user.deactivated === true) {
      return callback(null, { success: false, message: 'Profile is already deactivated', status: 409 });
    }

    const blockers = [];

    const walletSql = `
      SELECT COALESCE(SUM(c.refund_amount), 0) AS customer_credit
      FROM complaints c
      JOIN store s ON c.store_id = s.store_id
      WHERE s.owner_id = ?
        AND c.status = 'completed'
        AND c.refund_amount > 0
    `;

    db.query(walletSql, [userId], (walletErr, walletRows) => {
      if (walletErr) return callback(null, { success: false, message: 'Database error', error: walletErr.message });

      const balance = Number(walletRows[0]?.customer_credit || 0);
      if (balance > 0) blockers.push('customer credit for your store');

      const complaintsSql = `
        SELECT c.complaint_id
        FROM complaints c
        JOIN store s ON c.store_id = s.store_id
        WHERE s.owner_id = ?
          AND LOWER(COALESCE(c.status, '')) NOT IN ('completed', 'rejected')
        LIMIT 1
      `;

      db.query(complaintsSql, [userId], (complaintErr, complaintRows) => {
        if (complaintErr) return callback(null, { success: false, message: 'Database error', error: complaintErr.message });
        if (complaintRows.length > 0) blockers.push('unresolved complaints');

        const ordersSql = `
          SELECT o.order_id
          FROM orders o
          JOIN order_items oi ON o.order_id = oi.order_id
          JOIN products p ON oi.product_id = p.product_id
          JOIN store s ON p.store_id = s.store_id
          WHERE s.owner_id = ?
            AND LOWER(COALESCE(o.order_status, '')) NOT IN ('completed', 'cancelled', 'rejected')
          LIMIT 1
        `;

        db.query(ordersSql, [userId], (orderErr, orderRows) => {
          if (orderErr) return callback(null, { success: false, message: 'Database error', error: orderErr.message });
          if (orderRows.length > 0) blockers.push('active orders');

          callback(null, {
            success: true,
            canDeactivate: blockers.length === 0,
            blockers,
          });
        });
      });
    });
  });
};

// --- Check Seller Deactivation Eligibility ---
app.get('/api/seller/deactivate/eligibility/:userId', (req, res) => {
  const { userId } = req.params;

  getSellerDeactivationEligibility(userId, (err, result) => {
    if (err || !result?.success) {
      const status = result?.status || 500;
      return res.status(status).json(result || { success: false, message: 'Unable to verify seller deactivation eligibility' });
    }

    res.json({ success: true, canDeactivate: result.canDeactivate, blockers: result.blockers });
  });
});

// --- Deactivate Seller Profile ---
app.put('/api/seller/deactivate/:userId', (req, res) => {
  const { userId } = req.params;

  getSellerDeactivationEligibility(userId, (err, result) => {
    if (err || !result?.success) {
      const status = result?.status || 500;
      return res.status(status).json(result || { success: false, message: 'Unable to verify seller deactivation eligibility' });
    }

    if (!result.canDeactivate) {
      return res.status(409).json({ success: false, message: 'Cannot deactivate profile while there are outstanding issues for your store.', blockers: result.blockers });
    }

    db.query('UPDATE users SET has_access = 0, deactivated = 1 WHERE user_id = ?', [userId], (updateErr) => {
      if (updateErr) return res.status(500).json({ success: false, message: 'Database error', error: updateErr.message });

      db.query('UPDATE store SET has_access = 0 WHERE owner_id = ?', [userId], (storeErr) => {
        if (storeErr) return res.status(500).json({ success: false, message: 'Database error', error: storeErr.message });

        db.query(
          'UPDATE products SET is_visible = 2 WHERE is_active = 1 AND is_visible = 1 AND store_id IN (SELECT store_id FROM store WHERE owner_id = ?)',
          [userId],
          (productErr) => {
            if (productErr) return res.status(500).json({ success: false, message: 'Database error', error: productErr.message });

            res.json({ success: true, message: 'Seller profile deactivated successfully' });
          }
        );
      });
    });
  });
});

// --- Deactivate Customer Profile ---
app.put('/api/customer/deactivate/:userId', (req, res) => {
  const { userId } = req.params;

  db.query('UPDATE users SET has_access = 0, deactivated = 1 WHERE user_id = ?', [userId], (err, result) => {
    if (err) return res.status(500).json({ success: false, message: 'Database error', error: err.message });
    if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'User not found' });

    res.json({ success: true, message: 'Customer profile deactivated successfully' });
  });
});


// --- Forgot Password ---
app.post('/api/users/forgot_password', (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ message: 'Email is required' });

  db.query('SELECT user_id FROM users WHERE email = ?', [email], async (err, result) => {
    if (err || result.length === 0) return res.status(404).json({ message: 'Email not found' });

    const otp = generateOtp();
    otpStore[email] = { otp, expires: Date.now() + 5 * 60 * 1000 };

    try {
      await transporter.sendMail({
        from: '"FitAura"',
        to: email,
        subject: 'Reset your password',
        text: `Your OTP is: ${otp}`
      });
      res.status(200).json({ success: true });
    } catch {
      res.status(500).json({ message: 'Error sending email' });
    }
  });
});

app.post('/api/users/verify_otp', (req, res) => {
  const { email, otp } = req.body;
  const record = otpStore[email];

  if (record && record.otp === otp && record.expires > Date.now()) {
    return res.status(200).json({ success: true });
  }
  res.status(400).json({ message: 'Invalid or expired OTP' });
});

app.post('/api/users/reset_password', (req, res) => {
  const { email, password } = req.body;
  const hashed = bcrypt.hashSync(password, 10);

  db.query('UPDATE users SET password = ? WHERE email = ?', [hashed, email], (err) => {
    if (err) return res.status(500).json({ message: 'Failed to update' });
    delete otpStore[email];
    res.status(200).json({ success: true });
  });
});

app.post('/api/users/:userId/verify_password', (req, res) => {
  const { userId } = req.params;
  const { current_password } = req.body;

  if (!current_password) {
    return res.status(400).json({ message: 'Current password is required' });
  }

  db.query('SELECT password FROM users WHERE user_id = ?', [userId], (err, users) => {
    if (err || users.length === 0) return res.status(404).json({ message: 'User not found' });

    if (!bcrypt.compareSync(current_password, users[0].password)) {
      return res.status(401).json({ message: 'Incorrect current password' });
    }

    res.status(200).json({ success: true });
  });
});

app.put('/api/users/:userId/change_password', (req, res) => {
  const { userId } = req.params;
  const { current_password, new_password } = req.body;

  if (!current_password || !new_password) {
    return res.status(400).json({ message: 'Current and new passwords are required' });
  }

  db.query('SELECT password FROM users WHERE user_id = ?', [userId], (err, users) => {
    if (err || users.length === 0) return res.status(404).json({ message: 'User not found' });

    if (!bcrypt.compareSync(current_password, users[0].password)) {
      return res.status(401).json({ message: 'Incorrect current password' });
    }

    const hashed = bcrypt.hashSync(new_password, 10);
    db.query('UPDATE users SET password = ? WHERE user_id = ?', [hashed, userId], (err) => {
      if (err) return res.status(500).json({ message: 'Failed to update password' });
      res.status(200).json({ success: true, message: 'Password updated successfully' });
    });
  });
});


// --- Create Store ---
app.post('/api/stores', (req, res) => {
  const { user_id, role, store_name, logo, bio, website, instagram } = req.body;

  if (role.toLowerCase() !== 'seller') return res.status(403).json({ message: 'Only sellers can create stores' });

  const sql = `INSERT INTO store (owner_id, store_name, logo, bio, website, instagram, overall_rating) VALUES (?, ?, ?, ?, ?, ?, 0.0)`;
  db.query(sql, [user_id, store_name, logo || null, bio || null, website || null, instagram || null], (err, result) => {
    if (err) return res.status(500).json({ message: 'Failed to create store' });
    res.status(201).json({ success: true, store_id: result.insertId });
  });
});

app.put('/api/stores/:id', (req, res) => {
  const storeId = req.params.id;
  const { store_name, bio, website, instagram, logo } = req.body;

  const sql = `UPDATE store SET store_name = ?, bio = ?, website = ?, instagram = ?, logo = ?, has_access = 0 WHERE store_id = ?`;
  db.query(sql, [store_name, bio, website, instagram, logo, storeId], (err) => {
    if (err) return res.status(500).json({ success: false, message: 'Failed to update store' });

    db.query(
      'UPDATE products SET is_visible = 2 WHERE is_active = 1 AND is_visible = 1 AND store_id = ?',
      [storeId]
    );

    db.query('SELECT owner_id FROM store WHERE store_id = ?', [storeId], (err, stores) => {
      if (!err && stores.length > 0) {
        const ownerId = stores[0].owner_id;
        db.query('UPDATE users SET has_access = 0 WHERE user_id = ?', [ownerId]);

        notifyAllAdmins('Seller Profile Verification Required', `Store "${store_name}" updated details and requires re-approval.`);
      }
    });

    res.status(200).json({
      success: true,
      message: 'Store updated and pending re-verification',
      requires_reverification: true
    });
  });
});


// --- Get All Stores ---
app.get('/api/stores', (req, res) => {
  const query = `
    SELECT s.store_id, s.store_name, s.logo, s.bio,
           ROUND(IFNULL(AVG(product_stats.avg_rating), 0), 1) as overall_rating
    FROM store s
    LEFT JOIN (
      SELECT p.store_id, AVG(r.rating) as avg_rating
      FROM products p
      JOIN reviews r ON p.product_id = r.product_id
      GROUP BY p.product_id, p.store_id
    ) as product_stats ON s.store_id = product_stats.store_id
    WHERE s.has_access = 1
    GROUP BY s.store_id, s.store_name, s.logo, s.bio
  `;
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ success: false, message: 'Failed to fetch stores' });
    res.status(200).json({ success: true, data: results });
  });
});


// --- Get Store By User Id ---
app.get('/api/stores/user/:id', (req, res) => {
  const query = `
    SELECT s.store_id, s.owner_id, s.store_name, s.bio, s.logo, s.website, s.instagram, s.has_access,
           ROUND(IFNULL(AVG(product_stats.avg_rating), 0), 1) as overall_rating
    FROM store s
    LEFT JOIN (
      SELECT p.store_id, AVG(r.rating) as avg_rating
      FROM products p
      JOIN reviews r ON p.product_id = r.product_id
      GROUP BY p.product_id, p.store_id
    ) as product_stats ON s.store_id = product_stats.store_id
    WHERE s.owner_id = ?
    GROUP BY s.store_id, s.owner_id, s.store_name, s.bio, s.logo, s.website, s.instagram, s.has_access
  `;
  db.query(query, [req.params.id], (err, result) => {
    if (err || result.length === 0) return res.status(404).json({ message: 'Not found' });
    res.json(result[0]);
  });
});


// --- Get All Users (Admin) ---
app.get('/api/admin/users', (req, res) => {
  const sql = `SELECT u.*, ut.role FROM users u JOIN usertypes ut ON u.usertype_id = ut.usertype_id WHERE u.usertype_id != 3 ORDER BY u.user_id DESC`;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ success: false });
    res.json({ success: true, data: results });
  });
});


// --- 🔔 Notifications ---

app.get('/api/admin/notifications', (req, res) => {
  const query = `
    SELECT notification_id, user_id, title, message, is_read, created_at
    FROM notifications
    WHERE user_id IN (SELECT user_id FROM users WHERE usertype_id = 3)
    ORDER BY created_at DESC
  `;
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ success: false, message: 'Database error' });
    res.status(200).json({ success: true, notifications: results });
  });
});

app.put('/api/admin/notifications/:notificationId/read', (req, res) => {
  const { notificationId } = req.params;
  db.query('UPDATE notifications SET is_read = 1 WHERE notification_id = ?', [notificationId], (err, result) => {
    if (err) return res.status(500).json({ success: false });
    if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Notification not found' });
    res.status(200).json({ success: true });
  });
});

app.delete('/api/admin/notifications/:notificationId', (req, res) => {
  const { notificationId } = req.params;
  db.query('DELETE FROM notifications WHERE notification_id = ?', [notificationId], (err, result) => {
    if (err) return res.status(500).json({ success: false });
    if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Notification not found' });
    res.status(200).json({ success: true });
  });
});

app.get('/api/notifications/user/:userId', (req, res) => {
  const { userId } = req.params;
  const query = `
    SELECT notification_id, user_id, title, message, is_read, created_at
    FROM notifications
    WHERE user_id = ?
    ORDER BY created_at DESC
  `;
  db.query(query, [userId], (err, results) => {
    if (err) return res.status(500).json({ success: false });
    res.status(200).json({ success: true, notifications: results });
  });
});

app.put('/api/notifications/:notificationId/read', (req, res) => {
  const { notificationId } = req.params;
  db.query('UPDATE notifications SET is_read = 1 WHERE notification_id = ?', [notificationId], (err, result) => {
    if (err) return res.status(500).json({ success: false });
    if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Notification not found' });
    res.status(200).json({ success: true });
  });
});

app.delete('/api/notifications/:notificationId', (req, res) => {
  const { notificationId } = req.params;
  db.query('DELETE FROM notifications WHERE notification_id = ?', [notificationId], (err, result) => {
    if (err) return res.status(500).json({ success: false });
    if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Notification not found' });
    res.status(200).json({ success: true });
  });
});

// --- 📢 Admin: Send / Broadcast Notification ---
// target: 'specific_user' | 'all_customers' | 'all_sellers' | 'all_users'
app.post('/api/admin/send-notification', (req, res) => {
  const { title, message, target, user_id } = req.body;

  if (!title || !message || !target) {
    return res.status(400).json({ success: false, message: 'title, message, and target are required' });
  }

  const send = (userIds) => {
    if (!userIds || userIds.length === 0) {
      return res.status(200).json({ success: true, sent: 0 });
    }
    let completed = 0;
    let errored = false;
    userIds.forEach(uid => {
      db.query(
        'INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)',
        [uid, title, message],
        (err) => {
          if (err && !errored) {
            errored = true;
            return res.status(500).json({ success: false, message: 'Failed to insert some notifications' });
          }
          completed++;
          if (completed === userIds.length && !errored) {
            res.status(200).json({ success: true, sent: userIds.length });
          }
        }
      );
    });
  };

  if (target === 'specific_user') {
    if (!user_id) return res.status(400).json({ success: false, message: 'user_id is required for specific_user target' });
    const ids = Array.isArray(user_id) ? user_id.map(id => parseInt(id, 10)) : [parseInt(user_id, 10)];
    send(ids);
  } else if (target === 'all_customers') {
    db.query('SELECT user_id FROM users WHERE usertype_id = 1 AND has_access = 1', (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });
      send(rows.map(r => r.user_id));
    });
  } else if (target === 'all_sellers') {
    db.query('SELECT user_id FROM users WHERE usertype_id = 2 AND has_access = 1', (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });
      send(rows.map(r => r.user_id));
    });
  } else if (target === 'all_users') {
    db.query('SELECT user_id FROM users WHERE usertype_id IN (1, 2) AND has_access = 1', (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });
      send(rows.map(r => r.user_id));
    });
  } else {
    res.status(400).json({ success: false, message: 'Invalid target value' });
  }
});


// --- Update User Access Status (Admin) ---
app.put('/api/admin/users/:userId/access', (req, res) => {
  const { userId } = req.params;
  const { has_access } = req.body;

  db.query('UPDATE users SET has_access = ? WHERE user_id = ?', [has_access, userId], (err) => {
    if (err) return res.status(500).json({ success: false });

    db.query('UPDATE store SET has_access = ? WHERE owner_id = ?', [has_access, userId], () => {
      if (has_access === 1) {
        db.query(
          'UPDATE products SET is_visible = 1 WHERE is_visible = 2 AND store_id IN (SELECT store_id FROM store WHERE owner_id = ?)',
          [userId]
        );
      }

      db.query('SELECT email, name FROM users WHERE user_id = ?', [userId], (err, user) => {
        if (user && user.length > 0) {
          transporter.sendMail({
            from: '"FitAura"',
            to: user[0].email,
            subject: 'Account Status Updated',
            text: `Hello ${user[0].name}, your account access has been updated.`
          }).catch(() => { });

          const statusText = has_access === 1 ? 'approved' : 'suspended';
          sendNotification(userId, 'Account Status Updated', `Your account has been ${statusText} by the admin.`);
        }
      });

      res.json({ success: true });
    });
  });
});


// --- Get All Products — With Filters & Search ---
app.get('/api/products', (req, res) => {
  const { search, category, gender, minPrice, maxPrice, sortBy, sizes, colors, brand, admin } = req.query;

  let sql = `SELECT DISTINCT p.*, s.store_name, s.logo, s.owner_id as seller_id FROM products p 
             LEFT JOIN store s ON p.store_id = s.store_id 
             LEFT JOIN product_variants v ON p.product_id = v.product_id WHERE 1=1`;
  const params = [];

  if (admin !== 'true') sql += ' AND p.is_visible = 1 AND p.is_verified = 1';

  if (search) {
    sql += ' AND (p.product_name LIKE ? OR p.description LIKE ? OR s.store_name LIKE ?)';
    params.push(`%${search}%`, `%${search}%`, `%${search}%`);

    // Log search interaction
    const { userId } = req.query;
    if (userId) {
      db.query(
        'INSERT INTO user_interactions (user_id, interaction_type, search_query) VALUES (?, "search", ?)',
        [userId, search],
        () => { }
      );
    }
  }

  if (category && category !== 'All') { sql += ' AND p.category = ?'; params.push(category); }
  if (gender && gender !== 'All') { sql += ' AND LOWER(p.gender) = LOWER(?)'; params.push(gender); }
  if (minPrice) { sql += ' AND p.price >= ?'; params.push(parseFloat(minPrice)); }
  if (maxPrice) { sql += ' AND p.price <= ?'; params.push(parseFloat(maxPrice)); }
  if (brand && brand !== 'All') { sql += ' AND LOWER(s.store_name) = LOWER(?)'; params.push(brand); }

  if (sizes) {
    const list = Array.isArray(sizes) ? sizes : [sizes];
    sql += ` AND v.size IN (${list.map(() => '?').join(',')})`;
    params.push(...list);
  }
  if (colors) {
    const list = Array.isArray(colors) ? colors : [colors];
    sql += ` AND v.color IN (${list.map(() => '?').join(',')})`;
    params.push(...list);
  }

  if (sortBy === 'A to Z') sql += ' ORDER BY p.product_name ASC';
  else if (sortBy === 'Price: Low to High') sql += ' ORDER BY p.price ASC';
  else if (sortBy === 'Price: High to Low') sql += ' ORDER BY p.price DESC';
  else sql += ' ORDER BY p.product_id DESC';

  db.query(sql, params, (err, results) => {
    if (err) {
      return res.status(500).json({ success: false });
    }
    const products = results.map(p => ({
      ...p,
      product_images: p.product_images ? JSON.parse(p.product_images) : [],
      is_favorited: 0,
    }));

    const userId = parseInt(req.query.userId, 10);
    attachPromotionDiscounts(products, (enriched) => {
      if (userId) {
        getWishlistProductIdsByUser(userId, (error, productIds) => {
          if (!error) {
            enriched.forEach(product => {
              if (productIds.includes(product.product_id)) {
                product.is_favorited = 1;
              }
            });
          }
          res.json({ success: true, data: enriched });
        });
      } else {
        res.json({ success: true, data: enriched });
      }
    });
  });
});


// --- Create Product ---
app.post('/api/products', (req, res) => {
  const { user_id, product_name, category, gender, price, description, images, variants } = req.body;

  db.query('SELECT store_id FROM store WHERE owner_id = ?', [user_id], (err, store) => {
    if (err || store.length === 0) return res.status(404).json({ message: 'Store not found' });
    const store_id = store[0].store_id;

    const sql = `INSERT INTO products (store_id, product_name, category, gender, price, description, product_images, is_visible, is_verified) VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0)`;
    db.query(sql, [store_id, product_name, category, gender, price, description, JSON.stringify(images)], (err, result) => {
      if (err) return res.status(500).json({ message: 'Failed to add' });
      const productId = result.insertId;

      notifyAllAdmins('New Product Listing', `${product_name} has been added and requires verification`);

      if (variants && variants.length > 0) {
        const values = variants.map(v => [productId, v.size, v.color, v.price_per_variant, v.stock_quantity]);
        db.query('INSERT INTO product_variants (product_id, size, color, price_per_variant, stock_quantity) VALUES ?', [values], () => {
          res.status(201).json({ success: true, product_id: productId });
        });
      } else {
        res.status(201).json({ success: true, product_id: productId });
      }
    });
  });
});


// --- Get All Products For A Store ---
app.get('/api/products/store/:storeId', (req, res) => {
  const { storeId } = req.params;
  const { role } = req.query;

  let sql = `SELECT p.*, GROUP_CONCAT(DISTINCT v.color) as colors, GROUP_CONCAT(DISTINCT v.size) as sizes,
                IFNULL(stats.avg_rating, 0) as average_rating 
               FROM products p 
               LEFT JOIN product_variants v ON p.product_id = v.product_id 
               LEFT JOIN (
                 SELECT product_id, ROUND(AVG(rating), 1) as avg_rating
                 FROM reviews
                 GROUP BY product_id
               ) as stats ON p.product_id = stats.product_id
               WHERE p.store_id = ?`;

  if (role !== 'seller' && role !== 'admin') {
    sql += ' AND p.is_visible = 1 AND p.is_verified = 1';
  }
  sql += ' GROUP BY p.product_id';

  db.query(sql, [storeId], (err, results) => {
    if (err) return res.status(500).json({ success: false });
    const processed = results.map(p => ({
      ...p,
      product_images: p.product_images ? JSON.parse(p.product_images) : [],
      colors: p.colors ? p.colors.split(',') : [],
      sizes: p.sizes ? p.sizes.split(',') : [],
      is_favorited: 0,
    }));

    const userId = parseInt(req.query.userId, 10);
    attachPromotionDiscounts(processed, (enriched) => {
      if (userId) {
        getWishlistProductIdsByUser(userId, (error, productIds) => {
          if (!error) {
            enriched.forEach(product => {
              if (productIds.includes(product.product_id)) {
                product.is_favorited = 1;
              }
            });
          }
          res.json(enriched);
        });
      } else {
        res.json(enriched);
      }
    });
  });
});


// --- Get All Variants For A Product ---
app.get('/api/products/variants/:productId', (req, res) => {
  db.query('SELECT * FROM product_variants WHERE product_id = ?', [req.params.productId], (err, result) => {
    if (err) return res.status(500).json({ success: false });
    res.json({ success: true, variants: result });
  });
});


// --- Get Product By Product Id ---
app.get('/api/products/:productId', (req, res) => {
  const sql = `SELECT p.*, s.store_name, s.logo, s.owner_id as seller_id FROM products p LEFT JOIN store s ON p.store_id = s.store_id WHERE p.product_id = ?`;
  db.query(sql, [req.params.productId], (err, result) => {
    if (err || result.length === 0) return res.status(404).json({ success: false });
    const product = { ...result[0], product_images: result[0].product_images ? JSON.parse(result[0].product_images) : [], is_favorited: 0 };
    // Attach active promotion discount
    attachPromotionDiscounts([product], () => {
      const userId = parseInt(req.query.userId, 10);
      if (userId) {
        db.query(
          'SELECT 1 FROM user_interactions WHERE user_id = ? AND product_id = ? AND interaction_type = ?',
          [userId, req.params.productId, 'wishlist'],
          (err, rows) => {
            if (!err && rows.length > 0) {
              product.is_favorited = 1;
            }
            res.json({ success: true, data: product });
          }
        );
      } else {
        res.json({ success: true, data: product });
      }
    });
  });
});


// --- Wishlist ---
app.post('/api/wishlist', (req, res) => {
  const { user_id, product_id } = req.body;
  if (!user_id || !product_id) {
    return res.status(400).json({ success: false, message: 'user_id and product_id are required' });
  }

  db.query(
    'SELECT 1 FROM user_interactions WHERE user_id = ? AND product_id = ? AND interaction_type = ?',
    [user_id, product_id, 'wishlist'],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false });
      if (rows.length > 0) return res.json({ success: true });

      db.query(
        'INSERT INTO user_interactions (user_id, product_id, interaction_type) VALUES (?, ?, ?)',
        [user_id, product_id, 'wishlist'],
        (err) => {
          if (err) return res.status(500).json({ success: false });
          res.status(201).json({ success: true });
        }
      );
    }
  );
});

app.delete('/api/wishlist/:userId/:productId', (req, res) => {
  const { userId, productId } = req.params;
  db.query(
    'DELETE FROM user_interactions WHERE user_id = ? AND product_id = ? AND interaction_type = ?',
    [userId, productId, 'wishlist'],
    (err) => {
      if (err) return res.status(500).json({ success: false });
      res.json({ success: true });
    }
  );
});

app.get('/api/wishlist/:userId', (req, res) => {
  const { userId } = req.params;
  const sql = `SELECT p.*, s.store_name, s.logo, s.owner_id as seller_id, ui.timestamp as added_at
               FROM user_interactions ui
               JOIN products p ON ui.product_id = p.product_id
               LEFT JOIN store s ON p.store_id = s.store_id
               WHERE ui.user_id = ? AND ui.interaction_type = ? AND p.is_visible = 1 AND p.is_verified = 1
               ORDER BY ui.timestamp DESC`;

  db.query(sql, [userId, 'wishlist'], (err, results) => {
    if (err) return res.status(500).json({ success: false });
    const data = results.map(p => ({
      ...p,
      product_images: p.product_images ? JSON.parse(p.product_images) : [],
      is_favorited: 1,
    }));
    attachPromotionDiscounts(data, (enriched) => {
      res.json({ success: true, data: enriched });
    });
  });
});

app.get('/api/wishlist/count/:userId', (req, res) => {
  const { userId } = req.params;
  db.query(
    'SELECT COUNT(*) AS count FROM user_interactions WHERE user_id = ? AND interaction_type = ?',
    [userId, 'wishlist'],
    (err, results) => {
      if (err) return res.status(500).json({ success: false });
      res.json({ success: true, count: results[0]?.count ?? 0 });
    }
  );
});

// --- Update Product Verification Status (Admin) ---
app.put('/api/admin/products/:productId/verification', (req, res) => {
  const { productId } = req.params;
  const { is_verified } = req.body;

  db.query('UPDATE products SET is_verified = ?, is_visible = ? WHERE product_id = ?', [is_verified, is_verified === 1 ? 1 : 0, productId], (err) => {
    if (err) return res.status(500).json({ success: false });

    db.query('SELECT u.email FROM users u JOIN store s ON u.user_id = s.owner_id JOIN products p ON s.store_id = p.store_id WHERE p.product_id = ?', [productId], (err, user) => {
      if (user && user.length > 0) {
        transporter.sendMail({
          from: '"FitAura"',
          to: user[0].email,
          subject: 'Product Verification Update',
          text: `Your product status has been updated.`
        }).catch(() => { });
      }
    });

    db.query('SELECT s.owner_id, p.product_name FROM products p JOIN store s ON p.store_id = s.store_id WHERE p.product_id = ?', [productId], (err, productResult) => {
      if (!err && productResult.length > 0) {
        const { owner_id, product_name } = productResult[0];
        const statusText = is_verified === 1 ? 'Approved' : 'Rejected';
        sendNotification(owner_id, `Product ${statusText}`, `Your product "${product_name}" has been ${statusText.toLowerCase()}`);
      }
    });

    res.json({ success: true });
  });
});


// --- Update Product ---
app.put('/api/products/:productId', (req, res) => {
  const { productId } = req.params;
  const { product_name, category, gender, price, description, images, variants } = req.body;

  const sql = `UPDATE products SET product_name=?, category=?, gender=?, price=?, description=?, product_images=?, is_verified=0, is_visible=0 WHERE product_id=?`;
  db.query(sql, [product_name, category, gender, price, description, JSON.stringify(images), productId], (err) => {
    if (err) return res.status(500).json({ success: false });

    db.query('DELETE FROM product_variants WHERE product_id = ?', [productId], () => {
      notifyAllAdmins('Product Updated', `${product_name} has been updated and requires re-verification`);

      if (variants && variants.length > 0) {
        const values = variants.map(v => [productId, v.size, v.color, v.price_per_variant, v.stock_quantity]);
        db.query('INSERT INTO product_variants (product_id, size, color, price_per_variant, stock_quantity) VALUES ?', [values], (err) => {
          if (err) return res.status(500).json({ success: false, message: 'Failed to update variants' });
          res.json({ success: true });
        });
      } else {
        res.json({ success: true });
      }
    });
  });
});


// --- Delete Product ---
app.delete('/api/products/:productId', (req, res) => {
  db.query('UPDATE products SET is_visible = 0 WHERE product_id = ?', [req.params.productId], (err) => {
    if (err) return res.status(500).json({ success: false });
    res.json({ success: true });
  });
});


// --- Cart ---
app.post('/api/cart', (req, res) => {
  const { userId, productId, quantity, size, color } = req.body;
  const sql = `INSERT INTO cart (userId, productId, quantity, size, color) VALUES (?, ?, ?, ?, ?)`;
  db.query(sql, [userId, productId, quantity || 1, size, color], (err, result) => {
    if (err) return res.status(500).json({ success: false });
    res.status(201).json({ success: true, cartItemId: result.insertId });
  });
});

app.get('/api/cart/:userId', (req, res) => {
  const sql = `SELECT c.*, p.product_id, p.product_name, p.price, p.product_images, p.store_id, s.store_name,
               v.stock_quantity, v.price_per_variant
               FROM cart c 
               LEFT JOIN products p ON c.productId = p.product_id 
               LEFT JOIN store s ON p.store_id = s.store_id 
               LEFT JOIN product_variants v ON (c.productId = v.product_id AND c.size = v.size AND c.color = v.color)
               WHERE c.userId = ? ORDER BY c.addedAt DESC`;

  db.query(sql, [req.params.userId], (err, results) => {
    if (err) return res.status(500).json({ success: false });
    const items = results.map(item => ({ ...item, product_images: item.product_images ? JSON.parse(item.product_images) : [] }));
    attachPromotionDiscounts(items, (enriched) => {
      res.json({ success: true, data: enriched });
    });
  });
});

app.delete('/api/cart/:cartItemId', (req, res) => {
  db.query('DELETE FROM cart WHERE cartItemId = ?', [req.params.cartItemId], (err) => {
    if (err) return res.status(500).json({ success: false });
    res.json({ success: true });
  });
});

app.put('/api/cart/:cartItemId', (req, res) => {
  const { quantity, size, color } = req.body;
  let sql = 'UPDATE cart SET quantity = ?';
  const params = [quantity];

  if (size) { sql += ', size = ?'; params.push(size); }
  if (color) { sql += ', color = ?'; params.push(color); }
  sql += ' WHERE cartItemId = ?';
  params.push(req.params.cartItemId);

  db.query(sql, params, (err) => {
    if (err) return res.status(500).json({ success: false });
    res.json({ success: true });
  });
});


// --- Get Store Overall Rating By Product Id ---
app.get('/api/products/:productId/store-rating', (req, res) => {
  const sql = `
    SELECT ROUND(IFNULL(AVG(product_stats.avg_rating), 0), 1) as overall_rating
    FROM (
      SELECT p.store_id, AVG(r.rating) as avg_rating
      FROM products p
      JOIN reviews r ON p.product_id = r.product_id
      WHERE p.store_id = (SELECT store_id FROM products WHERE product_id = ?)
      GROUP BY p.product_id
    ) as product_stats
  `;
  db.query(sql, [req.params.productId], (err, result) => {
    if (err) return res.status(500).json({ success: false });
    const rating = (result[0]?.overall_rating || 0).toString();
    res.json({ success: true, overall_rating: rating });
  });
});


// --- Get Orders For A Specific Seller ---
app.get('/api/seller/orders/:userId', (req, res) => {
  db.query('SELECT store_id FROM store WHERE owner_id = ?', [req.params.userId], (err, store) => {
    if (err || store.length === 0) return res.status(404).json({ success: false });
    const storeId = store[0].store_id;

    const sql = `SELECT DISTINCT o.order_id as id, o.order_status as status, o.created_at, u.name as customer_name,
                 (SELECT SUM(oi.price * oi.quantity) FROM order_items oi JOIN products p ON oi.product_id = p.product_id 
                  WHERE oi.order_id = o.order_id AND p.store_id = ?) as total
                 FROM orders o JOIN users u ON o.customer_id = u.user_id
                 JOIN order_items oi ON o.order_id = oi.order_id
                 JOIN products p ON oi.product_id = p.product_id
                 WHERE p.store_id = ? ORDER BY o.created_at DESC`;

    db.query(sql, [storeId, storeId], (err, results) => {
      if (err) return res.status(500).json({ success: false });
      res.json({ success: true, data: results });
    });
  });
});


// --- Update Order Status ---
app.put('/api/orders/:orderId/status', (req, res) => {
  const { orderId } = req.params;
  const { status } = req.body;

  db.query('UPDATE orders SET order_status = ? WHERE order_id = ?', [status, orderId], (err, result) => {
    if (err) return res.status(500).json({ success: false });
    if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Order not found' });

    const sql = `
      SELECT o.customer_id, u.email, u.name 
      FROM orders o 
      JOIN users u ON o.customer_id = u.user_id 
      WHERE o.order_id = ?
    `;
    db.query(sql, [orderId], (err, order) => {
      if (!err && order.length > 0) {
        const customer = order[0];
        const statusUpper = status.charAt(0).toUpperCase() + status.slice(1);
        const title = `Order ${statusUpper}`;
        const message = `Dear ${customer.name}, your order #${orderId} has been updated to: ${statusUpper}.`;

        sendNotification(customer.customer_id, title, message);

        const mailOptions = {
          from: 'siya.santosh.kumar@gmail.com',
          to: customer.email,
          subject: title,
          text: message,
          html: `<p>Dear ${customer.name},</p><p>Your order <strong>#${orderId}</strong> status has been updated to: <strong>${statusUpper}</strong>.</p><p>Thank you for shopping with Fitaura!</p>`
        };

        transporter.sendMail(mailOptions).catch(() => { });
      }
    });

    res.json({ success: true });
  });
});


// --- Place Order ---
app.post('/api/orders', (req, res) => {
  const { customer_id, shipping_address, contact_number, shipping_type, payment_method, total_price, items } = req.body;

  let wallet_amount = 0;
  let cash_amount = Number(total_price) || 0;

  const orderSql = `INSERT INTO orders (customer_id, shipping_address, contact_number, shipping_type, payment_method, total_price, wallet_amount, cash_amount, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())`;
  db.query(orderSql, [customer_id, shipping_address, contact_number, shipping_type, payment_method, total_price, wallet_amount, cash_amount], (err, result) => {
    if (err) return res.status(500).json({ success: false });
    const orderId = result.insertId;

    const updateWalletAfterOrder = (callback) => {
      if (payment_method !== 'Wallet Credits') return callback(null);

      const storeIds = [...new Set(items.map(i => i.store_id).filter(id => id != null))];
      if (storeIds.length !== 1) {
        // If store_id is not passed in every order item, infer it from product IDs.
        const productIds = [...new Set(items.map(i => i.productId || i.product_id).filter(id => id != null))];
        if (productIds.length === 0) return callback(new Error('Wallet Credits only supported for single-store orders'));

        db.query('SELECT store_id FROM products WHERE product_id IN (?)', [productIds], (productErr, productRows) => {
          if (productErr) return callback(productErr);
          if (!productRows || productRows.length === 0) return callback(new Error('Store information not found for order items'));

          const uniqueStoreIds = [...new Set(productRows.map(r => r.store_id))];
          if (uniqueStoreIds.length !== 1) return callback(new Error('Wallet Credits only supported for single-store orders'));

          const storeId = uniqueStoreIds[0];
          return deductStoreCredit(storeId, callback);
        });
      } else {
        deductStoreCredit(storeIds[0], callback);
      }
    };

    const deductStoreCredit = (storeId, callback) => {
      db.query('SELECT balance FROM wallet_store_credit WHERE user_id = ? AND store_id = ?', [customer_id, storeId], (creditErr, creditRows) => {
        if (creditErr) return callback(creditErr);
        if (creditRows.length === 0) return callback(new Error('Store wallet credit not found'));

        const currentBalance = Number(creditRows[0].balance || 0);
        const amountToDeduct = Math.min(currentBalance, Number(total_price) || 0);
        if (amountToDeduct <= 0) return callback(null);

        db.query(
          'UPDATE wallet_store_credit SET balance = GREATEST(balance - ?, 0) WHERE user_id = ? AND store_id = ?',
          [amountToDeduct, customer_id, storeId],
          (storeUpdateErr) => {
            if (storeUpdateErr) return callback(storeUpdateErr);

            db.query('UPDATE wallet SET balance = GREATEST(balance - ?, 0) WHERE user_id = ?', [amountToDeduct, customer_id], (walletErr, walletResult) => {
              if (walletErr) return callback(walletErr);

              wallet_amount = amountToDeduct;
              cash_amount = (Number(total_price) || 0) - amountToDeduct;

              const updateOrderAmounts = () => {
                db.query(
                  'UPDATE orders SET wallet_amount = ?, cash_amount = ? WHERE order_id = ?',
                  [wallet_amount, cash_amount, orderId],
                  (orderUpdateErr) => {
                    if (orderUpdateErr) return callback(orderUpdateErr);
                    callback(null);
                  }
                );
              };

              if (walletResult.affectedRows === 0) {
                db.query('INSERT INTO wallet (user_id, balance) VALUES (?, 0.00)', [customer_id], (insertErr) => {
                  if (insertErr) return callback(insertErr);
                  updateOrderAmounts();
                });
              } else {
                updateOrderAmounts();
              }
            });
          }
        );
      });
    };

    const itemValues = items.map(i => [orderId, i.productId || i.product_id, i.variantId || 0, i.product_name, i.price, i.quantity, i.size, i.color]);
    db.query('INSERT INTO order_items (order_id, product_id, variant_id, product_name, price, quantity, size, color) VALUES ?', [itemValues], (err) => {
      if (err) return res.status(500).json({ success: false });

      updateWalletAfterOrder((walletErr) => {
        if (walletErr) {
          console.error('Failed to deduct wallet balance for order', orderId, walletErr);
          return res.status(500).json({ success: false, message: 'Failed to deduct wallet balance' });
        }

        db.query('DELETE FROM cart WHERE userId = ?', [customer_id], () => {
          const storeIds = [...new Set(items.map(i => i.store_id).filter(id => id))];
          if (storeIds.length > 0) {
            db.query('SELECT u.user_id, u.email, s.store_name FROM store s JOIN users u ON s.owner_id = u.user_id WHERE s.store_id IN (?)', [storeIds], (err, sellers) => {
              sellers?.forEach(s => {
                transporter.sendMail({
                  from: '"FitAura"',
                  to: s.email,
                  subject: `New Order #${orderId}`,
                  text: `You have a new order for ${s.store_name}!`
                }).catch(() => { });

                sendNotification(s.user_id, 'New Order Received', `You have received a new order #${orderId} for ${s.store_name}`);
              });
            });
          }

          sendNotification(customer_id, 'Order Placed', `Your order #${orderId} has been placed successfully`);

          db.query('SELECT email, name FROM users WHERE user_id = ?', [customer_id], (err, user) => {
            if (!err && user.length > 0) {
              transporter.sendMail({
                from: '"FitAura" <siya.santosh.kumar@gmail.com>',
                to: user[0].email,
                subject: `Order Placed Successfully - #${orderId}`,
                html: `
                  <p>Dear ${user[0].name},</p>
                  <p>Your order <strong>#${orderId}</strong> has been placed successfully.</p>
                  <p>Thank you for shopping with FitAura!</p>
                `
              }).catch(() => { });
            }
          });

          items.forEach(item => {
            const productId = item.productId || item.product_id;
            const { size, color, quantity } = item;
            db.query(
              'UPDATE product_variants SET stock_quantity = stock_quantity - ? WHERE product_id = ? AND size = ? AND color = ?',
              [quantity, productId, size, color],
              (err) => { }
            );
          });

          res.status(201).json({ success: true, orderId });
        });
      });
    });
  });
});


// --- Get Orders For A Specific Customer ---
app.get('/api/orders/customer/:userId', (req, res) => {
  const { userId } = req.params;
  const sql = `SELECT * FROM orders WHERE customer_id = ? ORDER BY created_at DESC`;

  db.query(sql, [userId], (err, results) => {
    if (err) {
      return res.status(500).json({ success: false });
    }
    res.json({ success: true, data: results });
  });
});


// --- Get Order Details ---
app.get('/api/orders/:orderId', (req, res) => {
  const { orderId } = req.params;
  const sql = `SELECT o.*, u.name as customer_name, u.email as customer_email, u.contact_number as customer_phone
               FROM orders o JOIN users u ON o.customer_id = u.user_id WHERE o.order_id = ?`;

  db.query(sql, [orderId], (err, order) => {
    if (err || order.length === 0) return res.status(404).json({ success: false });

    db.query('SELECT oi.*, p.product_images, p.store_id FROM order_items oi JOIN products p ON oi.product_id = p.product_id WHERE oi.order_id = ?', [orderId], (err, items) => {
      const processedItems = items.map(i => ({ ...i, image: i.product_images ? JSON.parse(i.product_images)[0] : null }));
      res.json({ success: true, data: { ...order[0], items: processedItems } });
    });
  });
});


// --- Get User By Id ---
app.get('/api/users/:userId', (req, res) => {
  db.query('SELECT * FROM users WHERE user_id = ?', [req.params.userId], (err, result) => {
    if (err || result.length === 0) return res.status(404).json({ success: false });
    res.json({ success: true, data: result[0] });
  });
});

// --- Get Wallet By User Id ---
app.get('/api/wallets/user/:userId', (req, res) => {
  const { userId } = req.params;
  const walletSql = 'SELECT wallet_id, user_id, balance FROM wallet WHERE user_id = ?';
  db.query(walletSql, [userId], (walletErr, walletRows) => {
    if (walletErr) {
      console.error('Wallet Query Error for user', userId, ':', walletErr);
      return res.status(500).json({ success: false, message: 'Database error fetching wallet', error: walletErr.message });
    }
    if (walletRows.length === 0) {
      return res.status(404).json({ success: false, message: 'Wallet not found' });
    }

    const transactionsSql = `
      SELECT
        'debit' AS type,
        total_price AS amount,
        CONCAT('Order #', order_id) AS description,
        created_at AS timestamp,
        CASE
          WHEN wallet_amount > 0 AND cash_amount > 0 THEN CONCAT('Paid via ', payment_method, ' (Rs. ', wallet_amount, ' wallet, Rs. ', cash_amount, ' cash)')
          WHEN wallet_amount > 0 THEN CONCAT('Paid via ', payment_method, ' (Rs. ', wallet_amount, ' wallet)')
          ELSE CONCAT('Paid via ', payment_method, ' (Rs. ', cash_amount, ' cash)')
        END AS method
      FROM orders
      WHERE customer_id = ?
      UNION ALL
      SELECT
        'credit' AS type,
        refund_amount AS amount,
        CONCAT('Complaint refund #', complaint_id) AS description,
        created_at AS timestamp,
        'Refund' AS method
      FROM complaints
      WHERE user_id = ? AND status = 'completed' AND refund_amount > 0
      ORDER BY timestamp DESC
    `;

    db.query(transactionsSql, [userId, userId], (txErr, txRows) => {
      if (txErr) {
        console.error('Wallet transactions query error for user', userId, ':', txErr);
        return res.status(500).json({ success: false, message: 'Database error fetching wallet history', error: txErr.message });
      }

      const storeCreditsSql = `
        SELECT
          wsc.store_id,
          s.store_name,
          wsc.balance
        FROM wallet_store_credit wsc
        LEFT JOIN store s ON wsc.store_id = s.store_id
        WHERE wsc.user_id = ?
        ORDER BY s.store_name
      `;

      db.query(storeCreditsSql, [userId], (storeErr, storeRows) => {
        if (storeErr) {
          console.error('Store credit query error for user', userId, ':', storeErr);
          return res.status(500).json({ success: false, message: 'Database error fetching store credits', error: storeErr.message });
        }

        const storeCredits = (storeRows || []).map((store) => ({
          store_id: store.store_id,
          store_name: store.store_name || 'Store',
          balance: Number(store.balance || 0),
        }));

        res.json({
          success: true,
          data: {
            wallet: walletRows[0],
            transactions: txRows,
            store_balances: storeCredits,
            store_credits: storeCredits,
          },
        });
      });
    });
  });
});

app.get('/api/wallets/store/:userId', (req, res) => {
  const { userId } = req.params;
  db.query('SELECT store_id FROM store WHERE owner_id = ?', [userId], (storeErr, storeRows) => {
    if (storeErr) {
      console.error('Store query error for user', userId, ':', storeErr);
      return res.status(500).json({ success: false, message: 'Database error fetching store', error: storeErr.message });
    }
    if (!storeRows || storeRows.length === 0) {
      return res.status(404).json({ success: false, message: 'Store not found for user' });
    }

    const storeId = storeRows[0].store_id;
    const walletSummarySql = `
      SELECT
        COALESCE(SUM(balance), 0) AS total_balance,
        COUNT(*) AS customer_count
      FROM wallet_store_credit
      WHERE store_id = ? AND balance > 0
    `;

    db.query(walletSummarySql, [storeId], (summaryErr, summaryRows) => {
      if (summaryErr) {
        console.error('Store wallet summary query error for store', storeId, ':', summaryErr);
        return res.status(500).json({ success: false, message: 'Database error fetching store wallet summary', error: summaryErr.message });
      }

      const walletTransactionsSql = `
        SELECT
          'credit' AS type,
          SUM(oi.price * oi.quantity) AS amount,
          CONCAT('Order #', o.order_id) AS description,
          o.created_at AS timestamp,
          CASE
            WHEN o.wallet_amount > 0 AND o.cash_amount > 0 THEN CONCAT('Wallet Rs. ', o.wallet_amount, ' + Cash Rs. ', o.cash_amount)
            WHEN o.wallet_amount > 0 THEN CONCAT('Wallet Rs. ', o.wallet_amount)
            WHEN LOWER(o.payment_method) LIKE '%cash%' THEN CONCAT('Cash on Delivery: Rs. ', o.cash_amount)
            ELSE CONCAT('Cash: Rs. ', o.cash_amount)
          END AS method
        FROM orders o
        JOIN order_items oi ON oi.order_id = o.order_id
        JOIN products p ON p.product_id = oi.product_id
        WHERE p.store_id = ? AND o.order_status = 'completed'
        GROUP BY o.order_id, o.created_at, o.wallet_amount, o.cash_amount, o.payment_method
        UNION ALL
        SELECT
          'debit' AS type,
          c.refund_amount AS amount,
          CONCAT('Complaint refund #', c.complaint_id) AS description,
          c.created_at AS timestamp,
          'Refund' AS method
        FROM complaints c
        WHERE c.store_id = ? AND c.status = 'completed' AND c.refund_amount > 0
        ORDER BY timestamp DESC
      `;

      db.query(walletTransactionsSql, [storeId, storeId], (txErr, txRows) => {
        if (txErr) {
          console.error('Store wallet transaction query error for store', storeId, ':', txErr);
          return res.status(500).json({ success: false, message: 'Database error fetching store wallet transactions', error: txErr.message });
        }

        res.json({
          success: true,
          data: {
            total_balance: Number(summaryRows[0]?.total_balance || 0),
            customer_count: Number(summaryRows[0]?.customer_count || 0),
            transactions: txRows,
          },
        });
      });
    });
  });
});


// --- Submit Review ---
app.post('/api/reviews', (req, res) => {
  const { order_id, product_id, customer_id, rating, comment } = req.body;
  const sql = `INSERT INTO reviews (order_id, product_id, customer_id, rating, comment) VALUES (?, ?, ?, ?, ?)`;
  db.query(sql, [order_id, product_id, customer_id, rating, comment], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, reviewId: result.insertId });
  });
});


// --- Get Reviews For A Product ---

// --- Get Reviews For A Product ---
app.get('/api/reviews/product/:productId', (req, res) => {
  const sql = `SELECT r.*, u.name as customer_name FROM reviews r JOIN users u ON r.customer_id = u.user_id WHERE r.product_id = ? ORDER BY r.created_at DESC`;
  db.query(sql, [req.params.productId], (err, results) => {
    if (err) return res.status(500).json({ success: false });
    res.json({ success: true, data: results });
  });
});


// --- Get Chat Inbox (Active Chats) ---
app.get('/api/messages/inbox/:userId', (req, res) => {
  const userId = req.params.userId;
  const sql = `
    SELECT 
      u.user_id as other_user_id, 
      u.name as other_user_name,
      u.profile_picture as other_user_profile_picture,
      s.logo as store_logo,
      MAX(m.created_at) as last_message_time,
      (SELECT message FROM messages WHERE (sender_id = u.user_id AND receiver_id = ?) OR (sender_id = ? AND receiver_id = u.user_id) ORDER BY created_at DESC LIMIT 1) as last_message,
      (SELECT sender_id FROM messages WHERE (sender_id = u.user_id AND receiver_id = ?) OR (sender_id = ? AND receiver_id = u.user_id) ORDER BY created_at DESC LIMIT 1) as last_message_sender_id,
      (SELECT COUNT(*) FROM messages WHERE sender_id = u.user_id AND receiver_id = ? AND is_read = 0) as unread_count
    FROM messages m
    JOIN users u ON (m.sender_id = u.user_id OR m.receiver_id = u.user_id)
    LEFT JOIN store s ON s.owner_id = u.user_id
    WHERE (m.sender_id = ? OR m.receiver_id = ?) AND u.user_id != ?
    GROUP BY u.user_id, u.name, u.profile_picture, s.logo
    ORDER BY last_message_time DESC
  `;
  db.query(sql, [userId, userId, userId, userId, userId, userId, userId, userId], (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, data: results });
  });
});


// --- Get Chat History ---
app.get('/api/messages/:userId/:otherUserId', (req, res) => {
  const { userId, otherUserId } = req.params;
  const sql = `
    SELECT m.*, u.name as sender_name 
    FROM messages m 
    JOIN users u ON m.sender_id = u.user_id 
    WHERE (m.sender_id = ? AND m.receiver_id = ?) OR (m.sender_id = ? AND m.receiver_id = ?) 
    ORDER BY m.created_at ASC
  `;
  db.query(sql, [userId, otherUserId, otherUserId, userId], (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, data: results });
  });
});


// --- Mark Messages As Read ---
app.put('/api/messages/:userId/:otherUserId/read', (req, res) => {
  const { userId, otherUserId } = req.params;
  const sql = `UPDATE messages SET is_read = 1 WHERE sender_id = ? AND receiver_id = ? AND is_read = 0`;
  db.query(sql, [otherUserId, userId], (err) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true });
  });
});


// --- Promotions API ---
const syncPromotionStatuses = (callback) => {
  const sql = `
    UPDATE promotions
    SET status = CASE
      WHEN status = -1 THEN -1
      WHEN status = 0 THEN 0
      WHEN CURDATE() < DATE(start_date) THEN 0
      WHEN CURDATE() > DATE(end_date) THEN 0
      ELSE 1
    END
    WHERE status != -1
  `;

  db.query(sql, (err) => {
    if (callback) callback(err);
  });
};

app.post('/api/promotions', (req, res) => {
  const { store_id, title, discount, start_date, end_date, product_ids } = req.body;
  if (!store_id || !title || !discount || !start_date || !end_date || !product_ids || product_ids.length === 0) {
    return res.status(400).json({ success: false, message: 'All fields are required' });
  }

  const today = new Date();
  const start = new Date(start_date);
  const end = new Date(end_date);
  const initialStatus = today < start || today > end ? 0 : 1;

  const sql = `INSERT INTO promotions (store_id, title, discount, start_date, end_date, status) VALUES (?, ?, ?, ?, ?, ?)`;
  db.query(sql, [store_id, title, discount, start_date, end_date, initialStatus], (err, result) => {
    if (err) return res.status(500).json({ success: false, message: 'Database error', error: err.message });
    const promotionId = result.insertId;

    const values = product_ids.map(id => [promotionId, id]);
    db.query('INSERT INTO promotion_products (promotion_id, product_id) VALUES ?', [values], (err) => {
      if (err) return res.status(500).json({ success: false, message: 'Failed to link products', error: err.message });
      res.status(201).json({ success: true, promotion_id: promotionId });
    });
  });
});

app.get('/api/promotions/store/:storeId', (req, res) => {
  const { storeId } = req.params;

  syncPromotionStatuses((err) => {
    if (err) return res.status(500).json({ success: false, message: 'Database error', error: err.message });

    const sql = `
      SELECT p.*, GROUP_CONCAT(prod.product_name SEPARATOR ', ') as product_names, GROUP_CONCAT(prod.product_id) as product_ids
      FROM promotions p
      LEFT JOIN promotion_products pp ON p.promotion_id = pp.promotion_id
      LEFT JOIN products prod ON pp.product_id = prod.product_id
      WHERE p.store_id = ? AND p.status != -1
      GROUP BY p.promotion_id
      ORDER BY p.promotion_id DESC
    `;
    db.query(sql, [storeId], (err, results) => {
      if (err) return res.status(500).json({ success: false, message: 'Database error', error: err.message });
      res.json({ success: true, data: results });
    });
  });
});

// --- Get Active Promotion Discounts Map (product_id → discount) ---
app.get('/api/promotions/discounts', (req, res) => {
  syncPromotionStatuses((err) => {
    if (err) return res.status(500).json({ success: false });

    const sql = `
      SELECT pp.product_id, MAX(pr.discount) AS discount
      FROM promotion_products pp
      JOIN promotions pr ON pp.promotion_id = pr.promotion_id
      WHERE pr.status = 1
        AND CURDATE() BETWEEN DATE(pr.start_date) AND DATE(pr.end_date)
      GROUP BY pp.product_id
    `;
    db.query(sql, (err, rows) => {
      if (err) return res.status(500).json({ success: false });
      const discounts = {};
      rows.forEach(row => { discounts[row.product_id] = row.discount; });
      res.json({ success: true, discounts });
    });
  });
});

// --- Update Promotion Status ---
app.put('/api/promotions/:promotionId/status', (req, res) => {
  const { promotionId } = req.params;
  const { status } = req.body;
  
  if (status === undefined) {
    return res.status(400).json({ success: false, message: 'Status is required' });
  }

  const sql = `UPDATE promotions SET status = ? WHERE promotion_id = ?`;
  db.query(sql, [status, promotionId], (err, result) => {
    if (err) return res.status(500).json({ success: false, message: 'Database error', error: err.message });
    if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Promotion not found' });
    res.json({ success: true, message: 'Promotion status updated successfully' });
  });
});

// --- Update Promotion ---
app.put('/api/promotions/:promotionId', (req, res) => {
  const { promotionId } = req.params;
  const { title, discount, start_date, end_date, product_ids } = req.body;

  if (!title || !discount || !start_date || !end_date || !product_ids || product_ids.length === 0) {
    return res.status(400).json({ success: false, message: 'All fields are required' });
  }

  const today = new Date();
  const start = new Date(start_date);
  const end = new Date(end_date);
  const nextStatus = today < start || today > end ? 0 : 1;

  const sql = `UPDATE promotions SET title = ?, discount = ?, start_date = ?, end_date = ?, status = ? WHERE promotion_id = ?`;
  db.query(sql, [title, discount, start_date, end_date, nextStatus, promotionId], (err) => {
    if (err) return res.status(500).json({ success: false, message: 'Database error', error: err.message });

    // Update product links by deleting old ones and inserting new ones
    db.query('DELETE FROM promotion_products WHERE promotion_id = ?', [promotionId], (err) => {
      if (err) return res.status(500).json({ success: false, message: 'Failed to clear old product links', error: err.message });

      const values = product_ids.map(id => [promotionId, id]);
      db.query('INSERT INTO promotion_products (promotion_id, product_id) VALUES ?', [values], (err) => {
        if (err) return res.status(500).json({ success: false, message: 'Failed to link new products', error: err.message });
        res.json({ success: true, message: 'Promotion updated successfully' });
      });
    });
  });
});

// --- Remove a Single Product From a Promotion ---
app.delete('/api/promotions/:promotionId/products/:productId', (req, res) => {
  const { promotionId, productId } = req.params;
  db.query(
    'DELETE FROM promotion_products WHERE promotion_id = ? AND product_id = ?',
    [promotionId, productId],
    (err) => {
      if (err) return res.status(500).json({ success: false, message: 'Database error', error: err.message });
      res.json({ success: true });
    }
  );
});



// --- 📝 Complaints API ---

// File a complaint
app.post('/api/complaints', (req, res) => {
  const { order_id, product_id, store_id, user_id, issue, description, images } = req.body;
  if (!order_id || !product_id || !store_id || !user_id || !issue || !description) {
    return res.status(400).json({ success: false, message: 'Missing required complaint fields' });
  }

  // Convert array of base64 images into a JSON string to store in LONGTEXT images column
  const imagesStr = Array.isArray(images) ? JSON.stringify(images) : null;

  const sql = `INSERT INTO complaints (order_id, product_id, store_id, user_id, issue, description, images) VALUES (?, ?, ?, ?, ?, ?, ?)`;
  db.query(sql, [order_id, product_id, store_id, user_id, issue, description, imagesStr], (err, results) => {
    if (err) return res.status(500).json({ success: false, message: 'Database error filing complaint', error: err.message });
    res.status(201).json({ success: true, complaint_id: results.insertId });
  });
});

// Notify customer and seller via email after a complaint is filed
app.post('/api/complaints/notify', async (req, res) => {
  const { complaint_id, order_id, product_id, store_id, user_id } = req.body;
  if (!complaint_id || !order_id || !product_id || !store_id || !user_id) {
    return res.status(400).json({ success: false, message: 'Missing required fields' });
  }
  try {
    // Fetch customer details
    const custSql = 'SELECT user_id, email, name FROM users WHERE user_id = ?';
    db.query(custSql, [user_id], (err, custRows) => {
      if (err || custRows.length === 0) {
        return res.status(500).json({ success: false, message: 'Error fetching customer info' });
      }
      const customer = custRows[0];

      // Fetch seller details via store
      const sellerSql = `SELECT u.user_id, u.email, u.name FROM store s JOIN users u ON s.owner_id = u.user_id WHERE s.store_id = ?`;
      db.query(sellerSql, [store_id], (err2, sellerRows) => {
        if (err2 || sellerRows.length === 0) {
          // still notify admin even if seller not found
          notifyAdminsOnly();
          return;
        }
        const seller = sellerRows[0];

        // Prepare recipients: seller and all admins (and customer for confirmation)
        const recipients = [];
        if (seller.email) recipients.push({ userId: seller.user_id, email: seller.email, name: seller.name, role: 'seller' });
        if (customer.email) recipients.push({ userId: customer.user_id, email: customer.email, name: customer.name, role: 'customer' });

        // Notify admins list
        db.query('SELECT user_id, email, name FROM users WHERE usertype_id = 3', (adminErr, adminRows) => {
          if (!adminErr && adminRows.length > 0) {
            adminRows.forEach((admin) => {
              recipients.push({ userId: admin.user_id, email: admin.email, name: admin.name, role: 'admin' });
            });
          }

          // Send in-app notifications to seller and admins (not customers)
          recipients.forEach(r => {
            if (r.role === 'seller' || r.role === 'admin') {
              sendNotification(r.userId, 'New Complaint Filed', `Complaint #${complaint_id} has been filed for product ${product_id}.`);
            }
          });

          // Build email content similar in style to admin-update email
          const emailPromises = recipients
            .filter(r => r.email)
            .map((r) => {
              const subject = r.role === 'customer' ? 'Your complaint has been received' : 'New complaint filed for your product';
              // Mirror the admin-update email structure so recipients see consistent fields
              const status = 'review';
              const decision = 'pending';
              const comment = 'No comment';
              const refund = '0.00';
              const footer = r.role === 'seller' ? '' : '\n\nPlease review it in the admin panel.';
              const text = `Hello ${r.name},\n\nA new complaint (ID: ${complaint_id}) has been filed.\n\nOrder ID: ${order_id}\nProduct ID: ${product_id}\nStore ID: ${store_id}\n\nStatus: ${status}\nDecision: ${decision}\nComment: ${comment}\nRefund Amount: ${refund}${footer}\n\nRegards,\nFitAura Team`;
              return transporter.sendMail({
                from: 'FitAura <siya.santosh.kumar@gmail.com>',
                to: r.email,
                subject,
                text,
              }).catch((emailErr) => console.error(`${r.role} complaint notification email error:`, emailErr));
            });

          Promise.all(emailPromises).finally(() => res.json({ success: true }));
        });
      });
    });

    function notifyAdminsOnly() {
      db.query('SELECT user_id, email, name FROM users WHERE usertype_id = 3', (adminErr, adminRows) => {
        if (!adminErr && adminRows.length > 0) {
          adminRows.forEach((admin) => sendNotification(admin.user_id, 'New Complaint Filed', `Complaint #${complaint_id} has been filed.`));
          const adminEmails = adminRows.map(a => a.email).filter(Boolean);
          const emailPromises = adminEmails.map(email => transporter.sendMail({
            from: 'FitAura <siya.santosh.kumar@gmail.com>',
            to: email,
            subject: 'New complaint filed',
            text: `Hello Admin,\n\nA new complaint (ID: ${complaint_id}) has been filed for product ${product_id} under order ${order_id}.\n\nRegards,\nFitAura Team`
          }).catch((e) => console.error('Admin complaint email error:', e)));
          Promise.all(emailPromises).finally(() => res.json({ success: true }));
        } else {
          res.json({ success: true });
        }
      });
    }
  } catch (e) {
    res.status(500).json({ success: false, message: e.toString() });
  }
});

// Get customer complaints
app.get('/api/complaints/user/:userId', (req, res) => {
  const { userId } = req.params;
  const sql = `
    SELECT c.*, p.product_name, p.product_images AS product_image
    FROM complaints c
    LEFT JOIN products p ON c.product_id = p.product_id
    WHERE c.user_id = ?
    ORDER BY c.created_at DESC
  `;
  db.query(sql, [userId], (err, rows) => {
    if (err) {
      console.error('Complaints Query Error for user', userId, ':', err);
      return res.status(500).json({ success: false, message: 'Database error fetching complaints', error: err.message, details: err });
    }
    console.log('Complaints for user', userId, ':', rows.length, 'records found');
    res.json({ success: true, data: rows });
  });
});

// Get complaints for a seller's store
app.get('/api/seller/complaints/:sellerId', (req, res) => {
  const { sellerId } = req.params;
  const sql = `
    SELECT c.*, p.product_name, p.product_images AS product_image, u.name AS customer_name, u.email AS customer_email, s.store_name
    FROM complaints c
    LEFT JOIN products p ON c.product_id = p.product_id
    LEFT JOIN users u ON c.user_id = u.user_id
    LEFT JOIN store s ON c.store_id = s.store_id
    WHERE s.owner_id = ?
    ORDER BY c.created_at DESC
  `;
  db.query(sql, [sellerId], (err, rows) => {
    if (err) return res.status(500).json({ success: false, message: 'Database error fetching seller complaints', error: err.message });
    res.json({ success: true, data: rows });
  });
});

// Get all complaints for admin
app.get('/api/admin/complaints', (req, res) => {
  const sql = `
    SELECT 
      c.*,
      p.product_name, p.product_images AS product_image, p.description AS product_description, 
      p.category AS product_category, p.gender AS product_gender, p.price AS product_price, p.is_verified,
      u.name AS customer_name, u.email AS customer_email,
      s.store_name,
      o.shipping_address, o.contact_number, o.shipping_type, o.payment_method, o.total_price, o.order_status, o.created_at AS order_date,
      oi.quantity AS order_quantity, oi.size AS order_size, oi.color AS order_color, oi.price AS order_item_price
    FROM complaints c
    LEFT JOIN products p ON c.product_id = p.product_id
    LEFT JOIN users u ON c.user_id = u.user_id
    LEFT JOIN store s ON c.store_id = s.store_id
    LEFT JOIN orders o ON c.order_id = o.order_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id AND c.product_id = oi.product_id
    ORDER BY c.created_at DESC
  `;
  db.query(sql, (err, rows) => {
    if (err) return res.status(500).json({ success: false, message: 'Database error fetching complaints for admin', error: err.message });
    res.json({ success: true, data: rows });
  });
});

// Update complaint details (admin review/complete/reject action)
app.put('/api/admin/complaints/:complaintId', (req, res) => {
  const { complaintId } = req.params;
  const { status, admin_decision, admin_verification, admin_comment, refund_amount } = req.body;

  if (!status) {
    return res.status(400).json({ success: false, message: 'Status is required' });
  }

  const comment = (admin_comment || '').toString().trim();
  if (comment && !/^[A-Za-z0-9\s.,]+$/.test(comment)) {
    return res.status(400).json({ success: false, message: 'Admin comment can only contain letters, numbers, spaces, commas, and dots.' });
  }

  if (comment) {
    const wordCount = comment.split(/\s+/).filter(Boolean).length;
    if (wordCount >= 50) {
      return res.status(400).json({ success: false, message: 'Admin comment must be less than 50 words.' });
    }
  }

  const refundValue = refund_amount === undefined || refund_amount === null || refund_amount === '' ? 0.00 : Number(refund_amount);
  if (Number.isNaN(refundValue) || refundValue < 0) {
    return res.status(400).json({ success: false, message: 'Refund amount must be a valid non-negative number.' });
  }

  const checkComplaintSql = 'SELECT status, refund_amount, user_id, store_id FROM complaints WHERE complaint_id = ?';
  db.query(checkComplaintSql, [complaintId], (checkErr, checkRows) => {
    if (checkErr) return res.status(500).json({ success: false, message: 'Database error fetching complaint', error: checkErr.message });
    if (checkRows.length === 0) return res.status(404).json({ success: false, message: 'Complaint not found' });

    const previousStatus = checkRows[0].status;
    const previousRefund = Number(checkRows[0].refund_amount) || 0.00;
    const customerId = checkRows[0].user_id;
    const complaintStoreId = checkRows[0].store_id;

    const sql = `
      UPDATE complaints 
      SET status = ?, admin_decision = ?, admin_verification = ?, admin_comment = ?, refund_amount = ?
      WHERE complaint_id = ?
    `;

    db.query(sql, [status, admin_decision, admin_verification, admin_comment, refundValue, complaintId], (err, results) => {
      if (err) return res.status(500).json({ success: false, message: 'Database error updating complaint status', error: err.message });
      if (results.affectedRows === 0) return res.status(404).json({ success: false, message: 'Complaint not found' });

      const balanceDiff = (() => {
        if (status === 'completed') {
          if (previousStatus === 'completed') {
            return refundValue - previousRefund;
          }
          return refundValue;
        }
        if (previousStatus === 'completed') {
          return -previousRefund;
        }
        return 0.00;
      })();

      const updateWalletBalance = (callback) => {
        if (balanceDiff === 0) return callback();

        const walletUpdateSql = 'UPDATE wallet SET balance = balance + ? WHERE user_id = ?';
        db.query(walletUpdateSql, [balanceDiff, customerId], (walletErr, walletResult) => {
          if (walletErr) {
            console.error('Failed to update wallet balance for user', customerId, walletErr);
            return callback(walletErr);
          }
          if (walletResult.affectedRows === 0) {
            db.query('INSERT INTO wallet (user_id, balance) VALUES (?, ?) ON DUPLICATE KEY UPDATE balance = balance + ?', [customerId, balanceDiff, balanceDiff], (insertErr) => callback(insertErr));
          } else {
            callback();
          }
        });
      };

      const updateStoreCreditBalance = (callback) => {
        if (balanceDiff === 0 || !complaintStoreId) return callback();

        db.query('SELECT balance FROM wallet_store_credit WHERE user_id = ? AND store_id = ?', [customerId, complaintStoreId], (creditErr, creditRows) => {
          if (creditErr) return callback(creditErr);
          const existingBalance = creditRows.length > 0 ? Number(creditRows[0].balance || 0) : 0;
          const newBalance = existingBalance + balanceDiff;

          if (creditRows.length > 0) {
            db.query('UPDATE wallet_store_credit SET balance = ? WHERE user_id = ? AND store_id = ?', [newBalance, customerId, complaintStoreId], (updateErr) => callback(updateErr));
          } else {
            db.query('INSERT INTO wallet_store_credit (user_id, store_id, balance) VALUES (?, ?, ?)', [customerId, complaintStoreId, newBalance], (insertErr) => callback(insertErr));
          }
        });
      };

      updateWalletBalance((walletErr) => {
        updateStoreCreditBalance((storeCreditErr) => {
          if (storeCreditErr) {
            console.error('Store credit update error after complaint status change', storeCreditErr);
          }

          const complaintSql = 'SELECT c.*, s.store_id, s.owner_id, u.email AS customer_email, u.name AS customer_name FROM complaints c JOIN store s ON c.store_id = s.store_id JOIN users u ON c.user_id = u.user_id WHERE c.complaint_id = ?';
          db.query(complaintSql, [complaintId], (complaintErr, complaintRows) => {
            if (walletErr) {
              console.error('Wallet update error after complaint status change', walletErr);
            }
            if (complaintErr || complaintRows.length === 0) {
              return res.json({ success: true, message: 'Complaint updated successfully' });
            }

            const complaint = complaintRows[0];
            const sellerSql = 'SELECT user_id, email, name FROM users WHERE user_id = ?';
            db.query(sellerSql, [complaint.owner_id], (sellerErr, sellerRows) => {
              const recipients = [];
              if (!sellerErr && sellerRows.length > 0) {
                const seller = sellerRows[0];
                recipients.push({ userId: seller.user_id, email: seller.email, name: seller.name, role: 'seller' });
              }

              if (complaint.customer_email) {
                recipients.push({ userId: complaint.user_id, email: complaint.customer_email, name: complaint.customer_name, role: 'customer' });
              }

              const notifyRecipients = () => {
                recipients.forEach((recipient) => {
                  sendNotification(recipient.userId, 'Complaint Updated', `Complaint #${complaintId} has been updated by admin.`);
                });

                const emailPromises = recipients
                  .filter((recipient) => recipient.email)
                  .map((recipient) => transporter.sendMail({
                    from: 'FitAura <siya.santosh.kumar@gmail.com>',
                    to: recipient.email,
                    subject: 'Complaint update from FitAura admin',
                    text: `Hello ${recipient.name},\n\nAdmin has updated complaint #${complaintId}.\n\nStatus: ${status}\nDecision: ${admin_decision || 'Pending'}\nComment: ${admin_comment || 'No comment'}\nRefund Amount: ${refundValue.toFixed(2)}\n\nRegards,\nFitAura Team`
                  }).catch((emailErr) => console.error(`${recipient.role} complaint update email error:`, emailErr)));

                Promise.all(emailPromises).finally(() => {
                  res.json({ success: true, message: 'Complaint updated successfully' });
                });
              };

              if (recipients.length > 0) {
                notifyRecipients();
              } else {
                res.json({ success: true, message: 'Complaint updated successfully' });
              }
            });
          });
        });
      });
    });
  });
});


// --- Start Server ---
syncPromotionStatuses((err) => {
  if (err) {
    console.error('Initial promotion status sync failed:', err.message);
  }
});

setInterval(() => {
  syncPromotionStatuses((err) => {
    if (err) {
      console.error('Scheduled promotion status sync failed:', err.message);
    }
  });
}, 60 * 60 * 1000);

server.listen(3000, () => {
});