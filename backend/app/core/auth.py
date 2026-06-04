"""
Authentication — Supabase JWT verification.

Usage in any endpoint:

    from app.core.auth import get_current_user

    @router.post("/")
    def create_something(current_user: uuid.UUID = Depends(get_current_user)):
        # current_user is the authenticated user's UUID (from auth.users)
        ...

The JWT is issued by Supabase Auth and sent by the frontend as:
    Authorization: Bearer <access_token>
"""
import uuid
import jwt  # PyJWT
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from app.core.config import settings

# Scheme that extracts the token from "Authorization: Bearer <token>"
security = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
) -> uuid.UUID:
    """
    Decode a Supabase JWT and return the user's UUID.

    Raises 401 if:
    - No token is provided
    - Token is expired
    - Token is malformed or signature doesn't match
    """
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated — send Authorization: Bearer <token>",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials

    if not settings.SUPABASE_URL or not settings.SUPABASE_ANON_KEY:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Supabase is not configured on this server.",
        )

    # Let Supabase itself verify the token. This avoids all crypto algorithm
    # issues (HS256 vs RS256 vs ES256) and missing public key problems.
    user_url = f"{settings.SUPABASE_URL}/auth/v1/user"
    
    import httpx
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.get(
                user_url,
                headers={
                    "Authorization": f"Bearer {token}",
                    "apikey": settings.SUPABASE_ANON_KEY
                }
            )
            
            if resp.status_code != 200:
                detail = "Token is invalid or expired"
                try:
                    err_data = resp.json()
                    detail = err_data.get("msg", detail)
                except Exception:
                    pass
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail=detail,
                    headers={"WWW-Authenticate": "Bearer"},
                )
                
            user_data = resp.json()
            user_id_str = user_data.get("id")
            
            if not user_id_str:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Token missing user 'id'",
                )
                
            return uuid.UUID(user_id_str)
            
        except httpx.RequestError as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to verify token with Supabase: {str(e)}",
            )
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid user ID format in token response",
            )


async def get_optional_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
) -> uuid.UUID | None:
    """
    Same as get_current_user but returns None instead of 401 if no token.
    Useful for endpoints that behave differently for logged-in vs anonymous users.
    """
    if credentials is None:
        return None

    try:
        return await get_current_user(credentials)
    except HTTPException:
        return None
