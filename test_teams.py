import asyncio
import os
from linear_client import LinearClient

async def main():
    client = LinearClient("lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
    async with client:
        query = """
        query {
            teams {
                nodes {
                    id
                    name
                    key
                }
            }
        }
        """
        result = await client.query(query)
        teams = result.get("teams", {}).get("nodes", [])
        for team in teams:
            print(f"  - {team['name']} (key: {team['key']}, id: {team['id']})")

asyncio.run(main())
