import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:3000";
  static const String fitRoomBaseUrl = "https://platform.fitroom.app/api/tryon/v2";
  static const String fitRoomApiKey = "ff5e01bd77a24980b887052e08e616818592e8eb20afd45ead45df527434643c";
  static const Map<String, String> _headers = {'Content-Type': 'application/json'};

  /// Internal helper: is ok.
  static bool _isOk(int status) => status == 200 || status == 201;

  /// Internal helper: error.
  static String _error(http.Response res, String def) {
    try {
      final data = jsonDecode(res.body);
      return data['message'] ?? def;
    } catch (e) {
      return def;
    }
  }

  /// Calls the Sign up API endpoint.
  static Future<Map<String, dynamic>> signUp({
    required String role, required String name, required String email, required String password,
  }) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/users'), headers: _headers, body: jsonEncode({
        'role': role.toLowerCase(), 'name': name, 'email': email, 'password': password,
      }));

      if (_isOk(res.statusCode)) {
        return {'success': true, 'message': jsonDecode(res.body)['message']};
      }
      return {'success': false, 'message': _error(res, 'Sign up failed')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Sign in API endpoint.
  static Future<Map<String, dynamic>> signIn({required String email, required String password}) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/users/signin'), headers: _headers, body: jsonEncode({
        'email': email, 'password': password,
      }));

      if (_isOk(res.statusCode)) {
        final data = jsonDecode(res.body);
        return {
          'success': true,
          'user_id': data['user_id'],
          'name': data['name'],
          'role': data['role'],
          'profile_completed': data['profile_completed'] ?? true,
          'store_completed': data['store_completed'] ?? true,
        };
      }
      return {'success': false, 'message': _error(res, 'Sign in failed')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Forgot password API endpoint.
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/users/forgot_password'), headers: _headers, body: jsonEncode({'email': email}));
      if (_isOk(res.statusCode)) {
        return {'success': true};
      }
      return {'success': false, 'message': _error(res, 'Failed to send OTP')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Reset password API endpoint.
  static Future<Map<String, dynamic>> resetPassword(String email, String newPassword) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/users/reset_password'), headers: _headers, body: jsonEncode({'email': email, 'password': newPassword}));
      if (_isOk(res.statusCode)) {
        return {'success': true};
      }
      return {'success': false, 'message': _error(res, 'Failed to reset password')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Verify otp API endpoint.
  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/users/verify_otp'), headers: _headers, body: jsonEncode({'email': email, 'otp': otp}));
      return {'success': _isOk(res.statusCode), 'message': _error(res, 'Failed')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Verify sign up otp API endpoint.
  static Future<Map<String, dynamic>> verifySignUpOtp(String email, String otp) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/users/verify_signup_otp'), headers: _headers, body: jsonEncode({'email': email, 'otp': otp}));
      if (_isOk(res.statusCode)) {
        final data = jsonDecode(res.body);
        return {'success': true, 'user_id': data['user_id']};
      }
      return {'success': false, 'message': _error(res, 'Failed')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Save store info API endpoint.
  static Future<Map<String, dynamic>> saveStoreInfo({
    required int userId, required String role, required String storeName, required String bio, 
    String? logo, String? website, String? instagram,
  }) async {
    try {
      final body = {'user_id': userId, 'role': role.toLowerCase(), 'store_name': storeName, 'bio': bio, 'logo': logo, 'website': website, 'instagram': instagram};
      final res = await http.post(Uri.parse('$baseUrl/api/stores'), headers: _headers, body: jsonEncode(body));
      return {'success': _isOk(res.statusCode), 'message': _error(res, 'Failed')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Get store info API endpoint.
  static Future<Map<String, dynamic>> getStoreInfo(int userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/stores/user/$userId'), headers: _headers);
      if (_isOk(res.statusCode)) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Update store info API endpoint.
  static Future<Map<String, dynamic>> updateStoreInfo({
    required int storeId, required String storeName, required String bio, 
    String? logo, String? website, String? instagram,
  }) async {
    try {
      final body = {'store_name': storeName, 'bio': bio, 'logo': logo, 'website': website, 'instagram': instagram};
      final res = await http.put(Uri.parse('$baseUrl/api/stores/$storeId'), headers: _headers, body: jsonEncode(body));
      if (_isOk(res.statusCode)) {
        final data = jsonDecode(res.body);
        return {'success': true, ...data};
      }
      return {'success': false, 'message': _error(res, 'Failed')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Get user by id API endpoint.
  static Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/users/$userId'), headers: _headers);
      if (_isOk(res.statusCode)) {
        return {'success': true, 'data': jsonDecode(res.body)['data']};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Update user access API endpoint.
  static Future<Map<String, dynamic>> updateUserAccess({required int userId, required int hasAccess}) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/api/admin/users/$userId/access'), headers: _headers, body: jsonEncode({'has_access': hasAccess}));
      return {'success': _isOk(res.statusCode)};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Update profile API endpoint.
  static Future<Map<String, dynamic>> updateProfile({
    required int userId, String? name, String? cnic, String? contactNumber, String? address, String? gender, String? profilePicture,
  }) async {
    try {
      final body = {
        'name': name,
        'cnic': cnic, 
        'contact_number': contactNumber, 
        'address': address, 
        'gender': gender, 
        'profile_picture': profilePicture
      };
      final res = await http.put(Uri.parse('$baseUrl/api/users/$userId'), headers: _headers, body: jsonEncode(body));
      if (_isOk(res.statusCode)) {
        final data = jsonDecode(res.body);
        return {'success': true, ...data};
      }
      return {'success': false, 'message': _error(res, 'Failed')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Verify password API endpoint.
  static Future<Map<String, dynamic>> verifyPassword({
    required int userId, required String currentPassword,
  }) async {
    try {
      final body = {'current_password': currentPassword};
      final res = await http.post(
        Uri.parse('$baseUrl/api/users/$userId/verify_password'), 
        headers: _headers, 
        body: jsonEncode(body)
      );
      if (_isOk(res.statusCode)) {
        return {'success': true};
      }
      return {'success': false, 'message': _error(res, 'Incorrect current password')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Change password API endpoint.
  static Future<Map<String, dynamic>> changePassword({
    required int userId, required String currentPassword, required String newPassword,
  }) async {
    try {
      final body = {
        'current_password': currentPassword,
        'new_password': newPassword,
      };
      final res = await http.put(Uri.parse('$baseUrl/api/users/$userId/change_password'), headers: _headers, body: jsonEncode(body));
      if (_isOk(res.statusCode)) {
        return {'success': true, 'message': jsonDecode(res.body)['message']};
      }
      return {'success': false, 'message': _error(res, 'Failed to change password')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Create product API endpoint.
  static Future<Map<String, dynamic>> createProduct({
    required int userId, required String productName, required String category, required String gender, 
    required double price, required String description, required List<String> images, List<Map<String, dynamic>>? variants,
  }) async {
    try {
      final body = {'user_id': userId, 'product_name': productName, 'category': category, 'gender': gender, 'price': price, 'description': description, 'images': images, 'variants': variants};
      final res = await http.post(Uri.parse('$baseUrl/api/products'), headers: _headers, body: jsonEncode(body));
      if (_isOk(res.statusCode)) return {'success': true, 'product_id': jsonDecode(res.body)['product_id']};
      return {'success': false, 'message': _error(res, 'Failed')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Update product API endpoint.
  static Future<Map<String, dynamic>> updateProduct({
    required int productId, required String productName, required String category, required String gender, 
    required double price, required String description, required List<String> images, List<Map<String, dynamic>>? variants,
  }) async {
    try {
      final body = {'product_name': productName, 'category': category, 'gender': gender, 'price': price, 'description': description, 'images': images, 'variants': variants};
      final res = await http.put(Uri.parse('$baseUrl/api/products/$productId'), headers: _headers, body: jsonEncode(body));
      return {'success': _isOk(res.statusCode)};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Delete product API endpoint.
  static Future<Map<String, dynamic>> deleteProduct(int productId) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/api/products/$productId'), headers: _headers);
      return {'success': _isOk(res.statusCode)};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Get store products API endpoint.
  static Future<Map<String, dynamic>> getStoreProducts(int storeId, {String? role}) async {
    try {
      String url = '$baseUrl/api/products/store/$storeId';
      if (role != null) url += '?role=$role';
      final res = await http.get(Uri.parse(url), headers: _headers);
      if (_isOk(res.statusCode)) return {'success': true, 'data': jsonDecode(res.body)};
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Get product by id API endpoint.
  static Future<Map<String, dynamic>> getProductById(String productId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/products/$productId'), headers: _headers);
      if (_isOk(res.statusCode)) return {'success': true, 'data': jsonDecode(res.body)['data']};
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Get all products API endpoint.
  static Future<Map<String, dynamic>> getAllProducts({
    String? search, String? category, String? gender, double? minPrice, double? maxPrice,
    String? sortBy, List<String>? sizes, List<String>? colors, String? brand, bool isAdmin = false,
  }) async {
    try {
      String url = '$baseUrl/api/products?';
      if (isAdmin) url += 'admin=true&';
      if (search != null) url += 'search=$search&';
      if (category != null && category != 'All') url += 'category=$category&';
      if (gender != null && gender != 'All') url += 'gender=$gender&';
      if (minPrice != null) url += 'minPrice=$minPrice&';
      if (maxPrice != null) url += 'maxPrice=$maxPrice&';
      if (sortBy != null) url += 'sortBy=$sortBy&';
      if (sizes != null && sizes.isNotEmpty) for (var s in sizes) url += 'sizes=$s&';
      if (colors != null && colors.isNotEmpty) for (var c in colors) url += 'colors=$c&';

      final res = await http.get(Uri.parse(url), headers: _headers);
      if (_isOk(res.statusCode)) {
        final data = jsonDecode(res.body);
        return {'success': true, 'data': data['data'] ?? data};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Add to cart API endpoint.
  static Future<Map<String, dynamic>> addToCart({
    required int userId, required int productId, required int quantity, required String size, required String color,
  }) async {
    try {
      final body = {'userId': userId, 'productId': productId, 'quantity': quantity, 'size': size, 'color': color};
      final res = await http.post(Uri.parse('$baseUrl/api/cart'), headers: _headers, body: jsonEncode(body));
      if (_isOk(res.statusCode)) return {'success': true, 'cartItemId': jsonDecode(res.body)['cartItemId']};
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Get cart items API endpoint.
  static Future<Map<String, dynamic>> getCartItems(int userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/cart/$userId'), headers: _headers);
      if (_isOk(res.statusCode)) {
        final data = jsonDecode(res.body);
        return {'success': true, 'data': data['data'] ?? data};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Get seller orders API endpoint.
  static Future<Map<String, dynamic>> getSellerOrders(int userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/seller/orders/$userId'), headers: _headers);
      if (_isOk(res.statusCode)) return {'success': true, 'data': jsonDecode(res.body)['data'] ?? []};
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Update product status API endpoint.
  static Future<Map<String, dynamic>> updateProductStatus({required int productId, required int isVerified}) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/api/admin/products/$productId/verification'), headers: _headers, body: jsonEncode({'is_verified': isVerified}));
      return {'success': _isOk(res.statusCode)};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Update cart item API endpoint.
  static Future<Map<String, dynamic>> updateCartItem({required int cartItemId, required int quantity, String? size, String? color}) async {
    try {
      final body = {'quantity': quantity, 'size': size, 'color': color};
      final res = await http.put(Uri.parse('$baseUrl/api/cart/$cartItemId'), headers: _headers, body: jsonEncode(body));
      return {'success': _isOk(res.statusCode)};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Update cart item quantity API endpoint.
  static Future<Map<String, dynamic>> updateCartItemQuantity(int cartItemId, int quantity) async {
    return await updateCartItem(cartItemId: cartItemId, quantity: quantity);
  }

  /// Calls the Delete cart item API endpoint.
  static Future<Map<String, dynamic>> deleteCartItem(int cartItemId) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/api/cart/$cartItemId'), headers: _headers);
      return {'success': _isOk(res.statusCode)};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Get product variants API endpoint.
  static Future<List<Map<String, dynamic>>> getProductVariants(int productId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/products/variants/$productId'), headers: _headers);
      if (_isOk(res.statusCode)) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['variants'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Calls the Get store rating API endpoint.
  static Future<Map<String, dynamic>> getStoreRating(int productId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/products/$productId/store-rating'), headers: _headers);
      if (_isOk(res.statusCode)) return {'success': true, 'overall_rating': jsonDecode(res.body)['overall_rating']};
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Place order API endpoint.
  static Future<Map<String, dynamic>> placeOrder({
    required int customer_id, required String shipping_address, required String contact_number,
    required String shipping_type, required String payment_method, required double total_price, required List<Map<String, dynamic>> items,
  }) async {
    try {
      final body = {'customer_id': customer_id, 'shipping_address': shipping_address, 'contact_number': contact_number, 'shipping_type': shipping_type, 'payment_method': payment_method, 'total_price': total_price, 'items': items};
      final res = await http.post(Uri.parse('$baseUrl/api/orders'), headers: _headers, body: jsonEncode(body));
      if (_isOk(res.statusCode)) return {'success': true, 'orderId': jsonDecode(res.body)['orderId']};
      return {'success': false, 'message': _error(res, 'Failed')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Update order status API endpoint.
  static Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/orders/$orderId/status'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      );
      if (_isOk(res.statusCode)) return {'success': true};
      return {'success': false, 'message': jsonDecode(res.body)['message'] ?? 'Failed to update order status'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Get order details API endpoint.
  static Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/orders/$orderId'), headers: _headers);
      if (_isOk(res.statusCode)) return {'success': true, 'data': jsonDecode(res.body)['data']};
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Get customer orders API endpoint.
  static Future<Map<String, dynamic>> getCustomerOrders(int userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/orders/customer/$userId'), headers: _headers);
      if (_isOk(res.statusCode)) return {'success': true, 'data': jsonDecode(res.body)['data'] ?? []};
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  /// Calls the Submit review API endpoint.
  static Future<Map<String, dynamic>> submitReview({
    required int orderId, required int productId, required int customerId, required int rating, String? comment,
  }) async {
    try {
      final body = {
        'order_id': orderId,
        'product_id': productId,
        'customer_id': customerId,
        'rating': rating,
        'comment': comment,
      };
      final res = await http.post(Uri.parse('$baseUrl/api/reviews'), headers: _headers, body: jsonEncode(body));
      return {'success': _isOk(res.statusCode)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Get product reviews API endpoint.
  static Future<Map<String, dynamic>> getProductReviews(int productId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/reviews/product/$productId'), headers: _headers);
      if (_isOk(res.statusCode)) return {'success': true, 'data': jsonDecode(res.body)['data'] ?? []};
      return {'success': false, 'data': []};
    } catch (e) {
      return {'success': false, 'data': []};
    }
  }

  /// Calls the Get chat history API endpoint.
  static Future<Map<String, dynamic>> getChatHistory(int userId, int otherUserId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/messages/$userId/$otherUserId'), headers: _headers);
      if (_isOk(res.statusCode)) return {'success': true, 'data': jsonDecode(res.body)['data'] ?? []};
      return {'success': false, 'message': 'Failed to load messages'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Get chat inbox API endpoint.
  static Future<Map<String, dynamic>> getChatInbox(int userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/messages/inbox/$userId'), headers: _headers);
      if (_isOk(res.statusCode)) return {'success': true, 'data': jsonDecode(res.body)['data'] ?? []};
      return {'success': false, 'message': 'Failed to load inbox'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Mark messages as read API endpoint.
  static Future<Map<String, dynamic>> markMessagesAsRead(int userId, int otherUserId) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/messages/$userId/$otherUserId/read'),
        headers: _headers,
      );
      return {'success': _isOk(res.statusCode)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Get all users API endpoint.
  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/users'), headers: _headers);
      return {'success': _isOk(res.statusCode), 'data': jsonDecode(res.body)['data'] ?? []};
    } catch (e) {
      return {'success': false, 'data': []};
    }
  }

  /// Calls the Get all stores API endpoint.
  static Future<Map<String, dynamic>> getAllStores() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/stores'), headers: _headers);
      return {'success': _isOk(res.statusCode), 'data': jsonDecode(res.body)['data'] ?? []};
    } catch (e) {
      return {'success': false, 'data': []};
    }
  }

  /// Calls the Get user notifications API endpoint.
  static Future<Map<String, dynamic>> getUserNotifications(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/user/$userId'),
        headers: _headers,
      );

      if (_isOk(response.statusCode)) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['notifications'] ?? [],
        };
      }
      return {'success': false, 'message': 'Failed to fetch notifications'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Get admin notifications API endpoint.
  static Future<Map<String, dynamic>> getAdminNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/notifications'),
        headers: _headers,
      );

      if (_isOk(response.statusCode)) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['notifications'] ?? [],
        };
      }
      return {'success': false, 'message': 'Failed to fetch notifications'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Mark notification read API endpoint.
  static Future<Map<String, dynamic>> markNotificationRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/notifications/$notificationId/read'),
        headers: _headers,
      );
      return {'success': _isOk(response.statusCode)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Mark admin notification read API endpoint.
  static Future<Map<String, dynamic>> markAdminNotificationRead(int notificationId) => markNotificationRead(notificationId);

  /// Calls the Mark user notification read API endpoint.
  static Future<Map<String, dynamic>> markUserNotificationRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
        headers: _headers,
      );
      return {'success': _isOk(response.statusCode)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Delete notification API endpoint.
  static Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/notifications/$notificationId'),
        headers: _headers,
      );
      return {'success': _isOk(response.statusCode)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Delete admin notification API endpoint.
  static Future<Map<String, dynamic>> deleteAdminNotification(int notificationId) => deleteNotification(notificationId);

  /// Calls the Delete user notification API endpoint.
  static Future<Map<String, dynamic>> deleteUserNotification(int notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/notifications/$notificationId'),
        headers: _headers,
      );
      return {'success': _isOk(response.statusCode)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Deactivate seller profile API endpoint.
  static Future<Map<String, dynamic>> deactivateSellerProfile(int userId) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/seller/deactivate/$userId'),
        headers: _headers,
      );
      if (_isOk(res.statusCode)) return {'success': true};
      return {'success': false, 'message': _error(res, 'Failed to deactivate profile')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Deactivate customer profile API endpoint.
  static Future<Map<String, dynamic>> deactivateCustomerProfile(int userId) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/customer/deactivate/$userId'),
        headers: _headers,
      );
      if (_isOk(res.statusCode)) return {'success': true};
      return {'success': false, 'message': _error(res, 'Failed to deactivate account')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Create try on task API endpoint.
  static Future<Map<String, dynamic>> createTryOnTask({
    required List<int> modelImageBytes,
    required List<int> clothImageBytes,
    required String clothType,
    bool hdMode = true,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$fitRoomBaseUrl/tasks'));
      request.headers['X-API-KEY'] = fitRoomApiKey;
      
      request.files.add(http.MultipartFile.fromBytes(
        'model_image',
        modelImageBytes,
        filename: 'model.jpg',
      ));
      
      request.files.add(http.MultipartFile.fromBytes(
        'cloth_image',
        clothImageBytes,
        filename: 'cloth.jpg',
      ));
      
      request.fields['cloth_type'] = clothType;
      request.fields['hd_mode'] = hdMode.toString();

      final streamRes = await request.send();
      final res = await http.Response.fromStream(streamRes);

      if (_isOk(res.statusCode)) {
        return {'success': true, ...jsonDecode(res.body)};
      }
      return {'success': false, 'message': _error(res, 'Failed to create try-on task')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Calls the Get try on task status API endpoint.
  static Future<Map<String, dynamic>> getTryOnTaskStatus(String taskId) async {
    try {
      final res = await http.get(
        Uri.parse('$fitRoomBaseUrl/tasks/$taskId'),
        headers: {'X-API-KEY': fitRoomApiKey},
      );

      if (_isOk(res.statusCode)) {
        return {'success': true, ...jsonDecode(res.body)};
      }
      return {'success': false, 'message': _error(res, 'Failed to get task status')};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
