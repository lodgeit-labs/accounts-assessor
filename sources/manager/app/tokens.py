from jose import jwt, JWTError
from datetime import datetime, timezone, timedelta


# openssl rand -hex 32
SECRET_KEY = "your_secret_key"  # Use the same key you used to create the token
ALGORITHM = "HS256"  # Use the same algorithm you used to create the token
ACCESS_TOKEN_EXPIRE_MINUTES = 369


def create_access_token(data: dict):
	to_encode = data.copy()
	expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
	to_encode.update({"exp": expire})
	encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
	return encoded_jwt
	
	
def decode_token(encoded_token: str):
	try:
		# Decode the token
		payload = jwt.decode(encoded_token, SECRET_KEY, algorithms=[ALGORITHM])

		# Get the 'exp' claim and check if the token has expired
		exp = payload.get('exp')
		if exp is not None and datetime.now(timezone.utc).timestamp() > exp:
			raise JWTError("Token has expired")

		return payload

	except JWTError as e:
		print(f"Token is invalid: {e}")
		return None


# Example usage:
encoded_token = create_access_token({"sub": "worker1234567890"})
token = decode_token(encoded_token)
print(token)
