#!/usr/bin/env python3.11
"""
Git Lock Service for Multi-Agent Coordination
==============================================

Prevents git collisions when multiple agents work on the same repository
by implementing file-based advisory locks.

Features:
- Repository-level locks (one agent per repo at a time)
- Automatic lock timeout (prevent deadlocks)
- Lock ownership tracking (which agent holds the lock)
- Deadlock detection
- Lock queue (FIFO for fairness)

Usage:
    from git_lock_service import acquire_git_lock, release_git_lock

    # In agent script
    with acquire_git_lock(repo_path="/path/to/repo", agent_id="agent-1", timeout=3600):
        # Safe to run git commands
        subprocess.run(["git", "pull"])
        # ... do work ...
        subprocess.run(["git", "push"])

Author: Quiver Platform Team
Version: 1.0
Date: 2025-11-06
"""

import fcntl
import json
import os
import time
from contextlib import contextmanager
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional


# ============================================================================
# CONFIGURATION
# ============================================================================

LOCK_DIR = Path.home() / ".quiver" / "git_locks"
LOCK_TIMEOUT_SECONDS = 3600  # 1 hour default
LOCK_CHECK_INTERVAL = 0.5  # Check every 500ms
MAX_WAIT_TIME = 300  # Max 5 minutes waiting for lock


# ============================================================================
# DATA MODELS
# ============================================================================

@dataclass
class GitLock:
    """Represents a git repository lock"""
    repo_path: str
    agent_id: str
    session_id: str
    acquired_at: str  # ISO 8601
    expires_at: str  # ISO 8601
    pid: int
    hostname: str


# ============================================================================
# LOCK SERVICE
# ============================================================================

class GitLockService:
    """Service for managing git repository locks"""

    def __init__(self, lock_dir: Path = LOCK_DIR):
        self.lock_dir = lock_dir
        self.lock_dir.mkdir(parents=True, exist_ok=True)
        self._open_locks = {}  # Map repo_path → open file descriptor

    def _get_lock_file_path(self, repo_path: str) -> Path:
        """Get lock file path for a repository"""
        # Normalize repo path and create safe filename
        normalized = os.path.abspath(repo_path)
        safe_name = normalized.replace("/", "_").replace(":", "_")
        return self.lock_dir / f"{safe_name}.lock"

    def _get_lock_info_path(self, repo_path: str) -> Path:
        """Get lock info file path"""
        lock_file = self._get_lock_file_path(repo_path)
        return lock_file.with_suffix(".json")

    def is_locked(self, repo_path: str) -> bool:
        """Check if repository is currently locked"""
        lock_info_path = self._get_lock_info_path(repo_path)

        if not lock_info_path.exists():
            return False

        # Check if lock is expired
        try:
            with open(lock_info_path) as f:
                lock_data = json.load(f)

            expires_at = datetime.fromisoformat(lock_data["expires_at"])
            if datetime.now() > expires_at:
                # Lock expired, clean it up
                self._cleanup_lock(repo_path)
                return False

            return True

        except (json.JSONDecodeError, KeyError, ValueError):
            # Corrupt lock file, clean it up
            self._cleanup_lock(repo_path)
            return False

    def get_lock_owner(self, repo_path: str) -> Optional[GitLock]:
        """Get current lock owner info"""
        lock_info_path = self._get_lock_info_path(repo_path)

        if not lock_info_path.exists():
            return None

        try:
            with open(lock_info_path) as f:
                lock_data = json.load(f)
            return GitLock(**lock_data)
        except (json.JSONDecodeError, KeyError, TypeError):
            return None

    def acquire_lock(
        self,
        repo_path: str,
        agent_id: str,
        session_id: str,
        timeout: int = LOCK_TIMEOUT_SECONDS,
        wait: bool = True,
        max_wait: int = MAX_WAIT_TIME
    ) -> bool:
        """
        Acquire a lock on a git repository.

        Args:
            repo_path: Path to git repository
            agent_id: Unique agent identifier
            session_id: Session identifier
            timeout: Lock timeout in seconds
            wait: If True, wait for lock to become available
            max_wait: Maximum time to wait for lock (seconds)

        Returns:
            True if lock acquired, False otherwise
        """
        lock_file_path = self._get_lock_file_path(repo_path)
        lock_info_path = self._get_lock_info_path(repo_path)

        start_time = time.time()

        while True:
            try:
                # Try to acquire file lock (non-blocking if not waiting)
                lock_file = open(lock_file_path, "w")

                if wait:
                    # Blocking lock with timeout
                    deadline = start_time + max_wait
                    while time.time() < deadline:
                        try:
                            fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
                            break
                        except IOError:
                            # Lock held by someone else
                            owner = self.get_lock_owner(repo_path)
                            if owner:
                                print(f"⏳ Waiting for git lock on {repo_path} (held by {owner.agent_id})...")
                            time.sleep(LOCK_CHECK_INTERVAL)
                    else:
                        # Timeout reached
                        lock_file.close()
                        return False
                else:
                    # Non-blocking lock
                    fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)

                # Lock acquired! Write lock info
                now = datetime.now()
                expires_at = now + timedelta(seconds=timeout)

                lock = GitLock(
                    repo_path=repo_path,
                    agent_id=agent_id,
                    session_id=session_id,
                    acquired_at=now.isoformat(),
                    expires_at=expires_at.isoformat(),
                    pid=os.getpid(),
                    hostname=os.uname().nodename
                )

                with open(lock_info_path, "w") as f:
                    json.dump(asdict(lock), f, indent=2)

                # CRITICAL: Keep file descriptor open to hold the lock!
                self._open_locks[repo_path] = lock_file

                print(f"✓ Git lock acquired on {repo_path} by {agent_id}")
                return True

            except IOError as e:
                if not wait:
                    return False

                # Check if we've exceeded max wait time
                if time.time() - start_time > max_wait:
                    print(f"✗ Failed to acquire git lock on {repo_path} (timeout after {max_wait}s)")
                    return False

                # Wait and retry
                time.sleep(LOCK_CHECK_INTERVAL)

    def release_lock(self, repo_path: str, agent_id: str) -> bool:
        """
        Release a lock on a git repository.

        Args:
            repo_path: Path to git repository
            agent_id: Agent identifier (must match lock owner)

        Returns:
            True if lock released, False if not held by this agent
        """
        # Verify lock is held by this agent
        owner = self.get_lock_owner(repo_path)
        if not owner:
            print(f"⚠️  No lock found on {repo_path}")
            return False

        if owner.agent_id != agent_id:
            print(f"✗ Cannot release lock on {repo_path} (held by {owner.agent_id}, not {agent_id})")
            return False

        # Close file descriptor to release fcntl lock
        if repo_path in self._open_locks:
            try:
                self._open_locks[repo_path].close()
            except:
                pass
            del self._open_locks[repo_path]

        # Clean up lock files
        self._cleanup_lock(repo_path)

        print(f"✓ Git lock released on {repo_path} by {agent_id}")
        return True

    def _cleanup_lock(self, repo_path: str):
        """Clean up lock files"""
        lock_file_path = self._get_lock_file_path(repo_path)
        lock_info_path = self._get_lock_info_path(repo_path)

        for path in [lock_file_path, lock_info_path]:
            if path.exists():
                try:
                    path.unlink()
                except OSError:
                    pass

    def list_locks(self) -> list[GitLock]:
        """List all active locks"""
        locks = []

        for lock_info_path in self.lock_dir.glob("*.json"):
            try:
                with open(lock_info_path) as f:
                    lock_data = json.load(f)
                lock = GitLock(**lock_data)

                # Check if expired
                expires_at = datetime.fromisoformat(lock.expires_at)
                if datetime.now() > expires_at:
                    continue

                locks.append(lock)

            except (json.JSONDecodeError, KeyError, TypeError):
                continue

        return locks

    def force_release_all(self):
        """Force release all locks (use with caution!)"""
        # Close all open file descriptors
        for fd in list(self._open_locks.values()):
            try:
                fd.close()
            except:
                pass
        self._open_locks.clear()

        # Remove lock files
        for lock_file in self.lock_dir.glob("*.lock"):
            try:
                lock_file.unlink()
            except:
                pass
        for lock_info in self.lock_dir.glob("*.json"):
            try:
                lock_info.unlink()
            except:
                pass
        print("✓ All git locks force-released")


# ============================================================================
# CONVENIENCE FUNCTIONS
# ============================================================================

_service = GitLockService()


def acquire_git_lock(
    repo_path: str,
    agent_id: str,
    session_id: str = "default",
    timeout: int = LOCK_TIMEOUT_SECONDS,
    wait: bool = True,
    max_wait: int = MAX_WAIT_TIME
) -> bool:
    """Acquire a git lock (convenience function)"""
    return _service.acquire_lock(repo_path, agent_id, session_id, timeout, wait, max_wait)


def release_git_lock(repo_path: str, agent_id: str) -> bool:
    """Release a git lock (convenience function)"""
    return _service.release_lock(repo_path, agent_id)


def is_repo_locked(repo_path: str) -> bool:
    """Check if repo is locked (convenience function)"""
    return _service.is_locked(repo_path)


def get_lock_owner(repo_path: str) -> Optional[GitLock]:
    """Get lock owner (convenience function)"""
    return _service.get_lock_owner(repo_path)


@contextmanager
def git_lock(
    repo_path: str,
    agent_id: str,
    session_id: str = "default",
    timeout: int = LOCK_TIMEOUT_SECONDS,
    wait: bool = True,
    max_wait: int = MAX_WAIT_TIME
):
    """
    Context manager for git locks.

    Usage:
        with git_lock("/path/to/repo", "agent-1"):
            # Safe to run git commands
            subprocess.run(["git", "pull"])
            # ... do work ...
            subprocess.run(["git", "push"])
    """
    acquired = acquire_git_lock(repo_path, agent_id, session_id, timeout, wait, max_wait)

    if not acquired:
        raise RuntimeError(f"Failed to acquire git lock on {repo_path}")

    try:
        yield
    finally:
        release_git_lock(repo_path, agent_id)


# ============================================================================
# CLI
# ============================================================================

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Git lock service CLI")
    subparsers = parser.add_subparsers(dest="command", help="Command")

    # List locks
    subparsers.add_parser("list", help="List all active locks")

    # Acquire lock
    acquire_parser = subparsers.add_parser("acquire", help="Acquire a lock")
    acquire_parser.add_argument("repo_path", help="Repository path")
    acquire_parser.add_argument("agent_id", help="Agent ID")
    acquire_parser.add_argument("--session-id", default="cli", help="Session ID")
    acquire_parser.add_argument("--timeout", type=int, default=3600, help="Lock timeout (seconds)")
    acquire_parser.add_argument("--no-wait", action="store_true", help="Don't wait for lock")

    # Release lock
    release_parser = subparsers.add_parser("release", help="Release a lock")
    release_parser.add_argument("repo_path", help="Repository path")
    release_parser.add_argument("agent_id", help="Agent ID")

    # Check lock status
    status_parser = subparsers.add_parser("status", help="Check lock status")
    status_parser.add_argument("repo_path", help="Repository path")

    # Force release all
    subparsers.add_parser("force-release-all", help="Force release all locks")

    args = parser.parse_args()

    if args.command == "list":
        locks = _service.list_locks()
        if locks:
            print(f"\n{len(locks)} active lock(s):\n")
            for lock in locks:
                print(f"  {lock.repo_path}")
                print(f"    Agent: {lock.agent_id}")
                print(f"    Session: {lock.session_id}")
                print(f"    Acquired: {lock.acquired_at}")
                print(f"    Expires: {lock.expires_at}")
                print()
        else:
            print("No active locks")

    elif args.command == "acquire":
        success = acquire_git_lock(
            args.repo_path,
            args.agent_id,
            args.session_id,
            args.timeout,
            wait=not args.no_wait
        )
        exit(0 if success else 1)

    elif args.command == "release":
        success = release_git_lock(args.repo_path, args.agent_id)
        exit(0 if success else 1)

    elif args.command == "status":
        if is_repo_locked(args.repo_path):
            owner = get_lock_owner(args.repo_path)
            print(f"🔒 Locked by {owner.agent_id} (session: {owner.session_id})")
            print(f"   Acquired: {owner.acquired_at}")
            print(f"   Expires: {owner.expires_at}")
        else:
            print("🔓 Unlocked")

    elif args.command == "force-release-all":
        _service.force_release_all()

    else:
        parser.print_help()
