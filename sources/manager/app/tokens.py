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




"""
User
is "OAuth2PasswordBearer" a misnomer? What i intend to pass through the Bearer header is not a password, and my scheme has nothing to do with oAuth2
ChatGPT

Yes, you're correct in your understanding. The term OAuth2PasswordBearer in FastAPI can indeed be a bit misleading, especially if you're not implementing a full OAuth2 password flow but simply using JWT tokens for authentication.

Here's a breakdown to clarify:

    Bearer Tokens: In HTTP authentication, a bearer token is a token that is sent in the Authorization header. The term "bearer" implies that the possessor of the token is authorized to access certain resources. The token itself is not a password but typically a cryptographically signed piece of data like a JWT.

    OAuth2PasswordBearer in FastAPI: In FastAPI, OAuth2PasswordBearer is a class that is used to extract the token from the Authorization header of the request. The name might suggest that it's only for OAuth2 password flows, but in reality, it's quite flexible and can be used whenever you need to secure an endpoint with a bearer token (like a JWT).

    Misnomer: The term is somewhat a misnomer if you're only using JWT for authentication and not implementing the full OAuth2 password flow. The OAuth2 password flow involves a client sending username and password to the server and receiving an access token (and optionally a refresh token) in return. The access token is then used in the same manner as a JWT in the Authorization header.
        If you're simply generating a JWT after verifying the user's credentials and expect the client to send this JWT in the Authorization header for subsequent requests, you're not strictly implementing the OAuth2 password flow. You're just using JWTs for authentication.

In summary, while OAuth2PasswordBearer in FastAPI is named for the OAuth2 password flow, it's commonly used for JWT authentication as well, even if the full OAuth2 flow isn't being implemented. It's a utility to help you extract and validate the token from the header, and you can use it as part of your authentication system without strictly adhering to all the OAuth2 specifications. If the naming bothers you and you want to avoid confusion, you might consider creating your own dependency in FastAPI that does the same job but is named more appropriately for your use case.

"""