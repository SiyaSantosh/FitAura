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

      delete otpStore[email];
      delete pendingSignups[email];

      if (hasAccess === 0) {
        notifyAllAdmins('New Account Request', `${pendingUser.name} has sent an account request`);
      }

      res.status(201).json({ success: true, user_id: result.insertId });
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
      product_images: p.product_images ? JSON.parse(p.product_images) : []
    }));
    res.json({ success: true, data: products });
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
      sizes: p.sizes ? p.sizes.split(',') : []
    }));
    res.json(processed);
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
    const product = { ...result[0], product_images: result[0].product_images ? JSON.parse(result[0].product_images) : [] };
    res.json({ success: true, data: product });
  });
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
  const sql = `SELECT c.*, p.product_name, p.price, p.product_images, p.store_id, s.store_name,
               v.stock_quantity, v.price_per_variant
               FROM cart c 
               LEFT JOIN products p ON c.productId = p.product_id 
               LEFT JOIN store s ON p.store_id = s.store_id 
               LEFT JOIN product_variants v ON (c.productId = v.product_id AND c.size = v.size AND c.color = v.color)
               WHERE c.userId = ? ORDER BY c.addedAt DESC`;

  db.query(sql, [req.params.userId], (err, results) => {
    if (err) return res.status(500).json({ success: false });
    const items = results.map(item => ({ ...item, product_images: item.product_images ? JSON.parse(item.product_images) : [] }));
    res.json({ success: true, data: items });
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

  const orderSql = `INSERT INTO orders (customer_id, shipping_address, contact_number, shipping_type, payment_method, total_price, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())`;
  db.query(orderSql, [customer_id, shipping_address, contact_number, shipping_type, payment_method, total_price], (err, result) => {
    if (err) return res.status(500).json({ success: false });
    const orderId = result.insertId;

    const itemValues = items.map(i => [orderId, i.productId || i.product_id, i.variantId || 0, i.product_name, i.price, i.quantity, i.size, i.color]);
    db.query('INSERT INTO order_items (order_id, product_id, variant_id, product_name, price, quantity, size, color) VALUES ?', [itemValues], (err) => {
      if (err) return res.status(500).json({ success: false });

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

    db.query('SELECT oi.*, p.product_images FROM order_items oi JOIN products p ON oi.product_id = p.product_id WHERE oi.order_id = ?', [orderId], (err, items) => {
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
      (SELECT sender_id FROM messages WHERE (sender_id = u.user_id AND receiver_id = ?) OR (sender_id = ? AND receiver_id = u.user_id) ORDER BY created_at DESC LIMIT 1) as last_message_sender_id
    FROM messages m
    JOIN users u ON (m.sender_id = u.user_id OR m.receiver_id = u.user_id)
    LEFT JOIN store s ON s.owner_id = u.user_id
    WHERE (m.sender_id = ? OR m.receiver_id = ?) AND u.user_id != ?
    GROUP BY u.user_id, u.name, u.profile_picture, s.logo
    ORDER BY last_message_time DESC
  `;
  db.query(sql, [userId, userId, userId, userId, userId, userId, userId], (err, results) => {
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


// --- Start Server ---
server.listen(3000, () => {
});