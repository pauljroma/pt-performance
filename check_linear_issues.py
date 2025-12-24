#!/usr/bin/env python3
"""Check current Linear issues for PT Performance project."""

import os
import json
import requests

LINEAR_API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
LINEAR_API_URL = "https://api.linear.app/graphql"

def query_linear(query):
    """Execute a GraphQL query against Linear API."""
    headers = {
        "Content-Type": "application/json",
        "Authorization": LINEAR_API_KEY
    }
    response = requests.post(
        LINEAR_API_URL,
        headers=headers,
        json={"query": query}
    )
    return response.json()

# Test connection
viewer_query = """
query {
  viewer {
    id
    name
    email
  }
}
"""

print("Testing Linear API connection...")
result = query_linear(viewer_query)
print(json.dumps(result, indent=2))

# Get all issues
issues_query = """
query {
  issues(first: 50, filter: {
    or: [
      { labels: { name: { eq: "build-44" } } }
      { labels: { name: { eq: "build-40" } } }
    ]
  }) {
    nodes {
      id
      identifier
      title
      state {
        name
      }
      labels {
        nodes {
          name
        }
      }
      createdAt
      updatedAt
    }
  }
}
"""

print("\n\nQuerying issues with build-44 or build-40 labels...")
result = query_linear(issues_query)
print(json.dumps(result, indent=2))
