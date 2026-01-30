"""
Unit Tests for Community API
"""
import pytest
from httpx import AsyncClient


class TestCommunityAPI:
    """Tests for community forum endpoints."""

    @pytest.mark.asyncio
    async def test_get_posts_empty(self, auth_client: AsyncClient):
        """Test fetching posts when empty."""
        response = await auth_client.get("/community/posts")
        assert response.status_code == 200
        data = response.json()
        assert "posts" in data
        assert data["total"] == 0

    @pytest.mark.asyncio
    async def test_create_post(self, auth_client: AsyncClient):
        """Test creating a new post."""
        post_data = {
            "title": "Test Post Title Here",
            "content": "This is the test content for the post. It should be long enough."
        }
        response = await auth_client.post("/community/posts", json=post_data)
        assert response.status_code == 201
        data = response.json()
        assert data["title"] == post_data["title"]
        assert data["content"] == post_data["content"]
        assert "id" in data
        assert data["likes_count"] == 0

    @pytest.mark.asyncio
    async def test_create_post_validation(self, auth_client: AsyncClient):
        """Test post validation - title too short."""
        post_data = {
            "title": "Hi",  # Too short
            "content": "This is the content."
        }
        response = await auth_client.post("/community/posts", json=post_data)
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_get_posts_after_create(self, auth_client: AsyncClient):
        """Test fetching posts after creation."""
        # Create a post first
        post_data = {
            "title": "Another Test Post",
            "content": "More test content here for testing purposes."
        }
        await auth_client.post("/community/posts", json=post_data)
        
        # Fetch posts
        response = await auth_client.get("/community/posts")
        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 1

    @pytest.mark.asyncio
    async def test_like_post(self, auth_client: AsyncClient):
        """Test liking a post."""
        # Create a post first
        post_data = {
            "title": "Post to Like Test",
            "content": "Content for the likeable post here."
        }
        create_response = await auth_client.post("/community/posts", json=post_data)
        post_id = create_response.json()["id"]
        
        # Like the post
        like_response = await auth_client.post(f"/community/posts/{post_id}/like")
        assert like_response.status_code == 200
        data = like_response.json()
        assert data["liked"] == True
        assert data["likes_count"] == 1

    @pytest.mark.asyncio
    async def test_add_comment(self, auth_client: AsyncClient):
        """Test adding a comment to a post."""
        # Create a post first
        post_data = {
            "title": "Post for Comments",
            "content": "Content for the commentable post here."
        }
        create_response = await auth_client.post("/community/posts", json=post_data)
        post_id = create_response.json()["id"]
        
        # Add comment
        comment_data = {"content": "This is a test comment!"}
        comment_response = await auth_client.post(
            f"/community/posts/{post_id}/comments", json=comment_data
        )
        assert comment_response.status_code == 201
        data = comment_response.json()
        assert data["content"] == comment_data["content"]
