# User-to-Restaurant Linking & Verification Guide

This document explains how the "Menu Intelligence" app links a user's account to a restaurant and verifies this connection on the frontend.

## 1. The Linking Process (Sign Up & Registration)

Linking is handled through **JWT (JSON Web Tokens)** and **Database Ownership Mapping**.

### Step A: User Sign Up / Login
When a user signs up or logs in via Supabase, they receive an **Access Token (JWT)**. This token contains their unique user ID (`sub` or `uid`).

### Step B: Restaurant Registration
When the user fills out the restaurant setup form, the frontend calls the backend API:
- **Endpoint**: `POST /api/v1/restaurants/`
- **Headers**: `Authorization: Bearer <JWT_TOKEN>`

### Step C: Backend Auto-Mapping
The backend extracts the `user_id` from the provided JWT. It then creates the restaurant record and sets the `owner_id` field to match the `user_id` of the token bearer.
**No manual linking ID is required from the frontend.**

---

## 2. The Verification Process (Frontend Entry)

Verification happens automatically every time the app launches or the user logs in.

### Step 1: Identity Check
The frontend calls the "Who Am I" endpoint:
- **Endpoint**: `GET /api/v1/auth/me`
- **Headers**: `Authorization: Bearer <JWT_TOKEN>`

### Step 2: Verification Response
The backend checks the `restaurants` table for any record where `owner_id == user_id`.
- **If Found**: Backend returns `{"restaurant_id": "uuid", "is_owner": true}`.
- **If Not Found**: Backend returns `{"restaurant_id": null, "is_owner": false}`.

### Step 3: Frontend Navigation
- If `restaurant_id` is present: Navigate directly to the **Retailer Dashboard**.
- If `restaurant_id` is null: Navigate to the **Restaurant Setup Screen**.

---

## 3. Code Reference

### Frontend Verification (RetailerProvider snippet)
```dart
Future<void> _checkOwnership() async {
  final token = supabase.auth.currentSession?.accessToken;
  final userData = await apiService.getAuthMe(token);
  
  if (userData['restaurant_id'] != null) {
    // User is verified owner -> Show Dashboard
    this.myRestaurant = await apiService.getRestaurant(userData['restaurant_id'].toString());
  } else {
    // User is new -> Show Setup
  }
}
```
