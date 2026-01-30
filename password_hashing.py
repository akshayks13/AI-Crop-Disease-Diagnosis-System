import bcrypt

password = "admin123".encode()
hashed = bcrypt.hashpw(password, bcrypt.gensalt()).decode()
print(hashed)
