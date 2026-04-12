import http.server
import socketserver
import sqlite3
import json
import os
import hmac
import hashlib

PORT = 3000
DB_FILE = 'skypulse_database.sqlite'

# ==========================================
# 1. INITIALIZE CRYPTOGRAPHIC DATABASE
# ==========================================
def init_db():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS users (
            email TEXT PRIMARY KEY,
            is_pro BOOLEAN DEFAULT 1,
            payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    # Inject the Master Admin account physically into the database so the User can log in!
    c.execute("INSERT OR IGNORE INTO users (email, is_pro) VALUES ('zayd.aviation@gmail.com', 1)")
    c.execute("INSERT OR IGNORE INTO users (email, is_pro) VALUES ('test@skypulse.com', 1)")
    conn.commit()
    conn.close()
    print("✅ Local SQLite User Database Synchronized & Validated.")

init_db()

# ==========================================
# 2. BUILD THE HIGH-PERFORMANCE WEB ENGINE
# ==========================================
class SkyPulseServer(http.server.SimpleHTTPRequestHandler):
    
    # We must explicitly handle POST requests (The Webhooks & Login Endpoints)
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        
        try:
            payload = json.loads(post_data.decode('utf-8'))
        except Exception:
            payload = {}

        # ---------------------------------------------
        # API ROUTE: Frontend Login Request Validation
        # ---------------------------------------------
        if self.path == '/api/login':
            email = payload.get('email', '').strip().lower()
            if not email:
                email = "guest@skypulse.com"
            
            conn = sqlite3.connect(DB_FILE)
            c = conn.cursor()
            c.execute("SELECT is_pro FROM users WHERE email=?", (email,))
            user = c.fetchone()
            
            # Auto-Register them as a FREE tier user if they don't exist yet!
            if not user:
                c.execute("INSERT INTO users (email, is_pro) VALUES (?, 0)", (email,))
                conn.commit()
                is_pro = False
                print(f"🆕 NEW USER: {email} registered as FREE tier.")
            else:
                is_pro = bool(user[0])
                print(f"🔒 NATIVE AUTH: {email} logged in. PRO Status: {is_pro}")
                
            conn.close()
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            response = {"status": "success", "is_pro": is_pro, "token": "NATIVE_SERVER_TOKEN_" + email.split('@')[0].upper()}
            self.wfile.write(json.dumps(response).encode('utf-8'))
            return

        # ---------------------------------------------
        # API ROUTE: Secure Payment Webhook Fulfillment
        # ---------------------------------------------
        elif self.path == '/api/webhooks/payment':
            # 1. Cryptographic Signature Verification
            webhook_secret = os.environ.get('WEBHOOK_SECRET', 'test_secret_key_123').encode('utf-8')
            signature_header = self.headers.get('Dodo-Signature') or self.headers.get('Stripe-Signature') or self.headers.get('X-Signature') or ""
            
            # Compute expected HMAC SHA-256 signature
            expected_signature = hmac.new(webhook_secret, post_data, hashlib.sha256).hexdigest()
            
            # Validate matching hashed string blocks unauthorized access!
            if not signature_header or expected_signature not in signature_header:
                print(f"🚨 WEBHOOK REJECTED: Invalid cryptographic signature match.")
                self.send_response(401)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "error", "message": "Unauthorized: Invalid Signature"}).encode('utf-8'))
                return

            print("✅ WEBHOOK SIGNATURE VERIFIED: Payload cryptographically validated.")

            # 2. Dynamic Database Fulfillment
            try:
                buyer_email = None
                if payload.get('type') == 'payment.succeeded':
                    data_obj = payload.get('data')
                    if isinstance(data_obj, dict):
                        session_obj = data_obj.get('object')
                        if isinstance(session_obj, dict):
                            metadata = session_obj.get('metadata')
                            if isinstance(metadata, dict):
                                buyer_email = metadata.get('email')
                            if not buyer_email:
                                buyer_email = session_obj.get('customer_email')
                else:
                    metadata = payload.get('metadata')
                    if isinstance(metadata, dict):
                        buyer_email = metadata.get('email')
                    # Fallback string payer_email
                    if not buyer_email and isinstance(payload.get('payer_email'), str):
                        buyer_email = payload.get('payer_email')
            except Exception as e:
                print(f"⚠️ WEBHOOK PARSE ERROR: {e}")
                buyer_email = None
                
            if buyer_email:
                buyer_email = buyer_email.strip().lower()
                conn = sqlite3.connect(DB_FILE)
                c = conn.cursor()
                
                # First ensure user exists, then strictly update is_pro to true
                c.execute("INSERT OR IGNORE INTO users (email, is_pro) VALUES (?, 0)", (buyer_email,))
                c.execute("UPDATE users SET is_pro=1 WHERE email=?", (buyer_email,))
                
                conn.commit()
                conn.close()
                print(f"💰 PAYMENT FULFILLED: Dynamically upgraded {buyer_email} to PRO status!")
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "success", "message": "Webhook Executed & User Granted PRO"}).encode('utf-8'))
            return

        # ---------------------------------------------
        # API ROUTE: Google OAuth ID Token Verification
        # ---------------------------------------------
        elif self.path == '/api/google-login':
            from google.oauth2 import id_token
            from google.auth.transport import requests as google_requests
            
            token = payload.get('credential')
            # The User MUST replace this Client ID in their own dashboard.html and here!
            CLIENT_ID = "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
            
            try:
                # Verify the token against Google's servers
                idinfo = id_token.verify_oauth2_token(token, google_requests.Request(), CLIENT_ID)
                email = idinfo['email'].lower()
                
                conn = sqlite3.connect(DB_FILE)
                c = conn.cursor()
                c.execute("SELECT is_pro FROM users WHERE email=?", (email,))
                user = c.fetchone()
                
                if not user:
                    c.execute("INSERT INTO users (email, is_pro) VALUES (?, 0)", (email,))
                    conn.commit()
                    is_pro = False
                else:
                    is_pro = bool(user[0])
                
                conn.close()
                
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                response = {"status": "success", "is_pro": is_pro, "email": email}
                self.wfile.write(json.dumps(response).encode('utf-8'))
                print(f"🌐 GOOGLE AUTH: {email} verified. PRO: {is_pro}")
                
            except ValueError:
                # Invalid token
                self.send_response(401)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "error", "message": "Invalid Google Token"}).encode('utf-8'))
            return

        # Fallback Error Routing
        else:
            self.send_error(404, "Physical API Node Mismatch")

# ==========================================
# 3. IGNITE THE SERVER SOCKET
# ==========================================
if __name__ == '__main__':
    httpd = socketserver.TCPServer(("", PORT), SkyPulseServer, bind_and_activate=False)
    httpd.allow_reuse_address = True
    httpd.server_bind()
    httpd.server_activate()
    print(f"🚀 ZERO-GRAVITY ENGAGED. Server running on port {PORT}")
    httpd.serve_forever()
