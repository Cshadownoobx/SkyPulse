# ============================================================
# Aviation Website — Feature Flags (Python)
# ============================================================

from __future__ import annotations

import fnmatch
import hashlib
from dataclasses import dataclass, field
from typing import Literal, Optional

Environment = Literal["dev", "staging", "prod"]


# ── Flag definition ──────────────────────────────────────────

@dataclass
class FeatureFlag:
    id: str
    name: str
    description: str
    enabled: bool
    rollout_percentage: int          # 0–100
    environments: list[Environment]


# ── Flag registry ────────────────────────────────────────────

DEFAULT_FLAGS: list[FeatureFlag] = [
    FeatureFlag(
        id="live_flight_map",
        name="Live flight map",
        description="Real-time aircraft positions via ADS-B data.",
        enabled=True,
        rollout_percentage=100,
        environments=["prod", "staging", "dev"],
    ),
    FeatureFlag(
        id="flight_status_alerts",
        name="Flight status alerts",
        description="Push notifications for delays, gate changes, and arrivals.",
        enabled=True,
        rollout_percentage=100,
        environments=["prod", "staging", "dev"],
    ),
    FeatureFlag(
        id="airport_info_panel",
        name="Airport info panel",
        description="Terminal maps, lounges, and live security wait times.",
        enabled=True,
        rollout_percentage=100,
        environments=["prod", "staging", "dev"],
    ),
    FeatureFlag(
        id="flight_history",
        name="Flight history tracker",
        description="30-day history of any flight — delays, routes, on-time stats.",
        enabled=True,
        rollout_percentage=40,
        environments=["staging", "dev"],
    ),
    FeatureFlag(
        id="weather_overlay",
        name="Weather overlay",
        description="Radar, turbulence, and wind layers on the flight map.",
        enabled=True,
        rollout_percentage=60,
        environments=["staging", "dev"],
    ),
    FeatureFlag(
        id="airline_comparison",
        name="Airline on-time comparison",
        description="Compare punctuality scores across airlines and routes.",
        enabled=False,
        rollout_percentage=0,
        environments=["dev"],
    ),
    FeatureFlag(
        id="price_tracker",
        name="Price tracker",
        description="Track fare changes and receive price drop alerts.",
        enabled=False,
        rollout_percentage=0,
        environments=["dev"],
    ),
    FeatureFlag(
        id="co2_emissions",
        name="CO2 emissions estimate",
        description="Carbon footprint per flight based on aircraft type and distance.",
        enabled=False,
        rollout_percentage=0,
        environments=["dev"],
    ),
]


# ── Flag manager ─────────────────────────────────────────────

class FeatureFlagManager:
    """
    Manages feature flags for the aviation website.

    Usage:
        flags = FeatureFlagManager(env="prod")
        if flags.is_enabled("live_flight_map", user_id=user.id):
            render_live_map()
    """

    def __init__(self, env: Environment) -> None:
        self.env = env
        self._flags: dict[str, FeatureFlag] = {
            f.id: FeatureFlag(**f.__dict__) for f in DEFAULT_FLAGS
        }

    # ── Public API ───────────────────────────────────────────

    def is_enabled(self, flag_id: str, user_id: Optional[str] = None) -> bool:
        """
        Return True if the flag is active for this user in the current env.

        Partial rollouts use a stable hash of (user_id + flag_id) so the
        same user always gets the same result.
        """
        flag = self._flags.get(flag_id)

        if flag is None:
            print(f"[FeatureFlags] Warning: unknown flag '{flag_id}'")
            return False

        # Must be enabled and available in current environment
        if not flag.enabled or self.env not in flag.environments:
            return False

        # Full rollout
        if flag.rollout_percentage >= 100:
            return True

        # Kill switch
        if flag.rollout_percentage <= 0:
            return False

        # Partial rollout — stable bucket by user_id
        bucket = self._hash_user(user_id, flag_id) if user_id else self._random_bucket()
        return bucket < flag.rollout_percentage

    def get_flag(self, flag_id: str) -> Optional[FeatureFlag]:
        """Return a flag's full config, or None if not found."""
        return self._flags.get(flag_id)

    def get_all_for_env(self) -> list[FeatureFlag]:
        """Return all flags available in the current environment."""
        return [f for f in self._flags.values() if self.env in f.environments]

    def override(self, flag_id: str, **kwargs) -> None:
        """
        Patch a flag at runtime — useful for remote config or tests.

        Example:
            flags.override("live_flight_map", enabled=False)
            flags.override("weather_overlay", rollout_percentage=80)
        """
        flag = self._flags.get(flag_id)
        if flag is None:
            print(f"[FeatureFlags] Warning: cannot override unknown flag '{flag_id}'")
            return
        for key, value in kwargs.items():
            if hasattr(flag, key):
                setattr(flag, key, value)
            else:
                print(f"[FeatureFlags] Warning: unknown field '{key}' on flag '{flag_id}'")

    def summary(self) -> None:
        """Print a human-readable summary of all flags for this environment."""
        flags = self.get_all_for_env()
        print(f"\n{'─' * 52}")
        print(f"  Feature flags  ·  env={self.env}  ·  {len(flags)} flags")
        print(f"{'─' * 52}")
        for f in flags:
            status = "ON " if f.enabled else "OFF"
            rollout = f"  ({f.rollout_percentage}% rollout)" if 0 < f.rollout_percentage < 100 else ""
            print(f"  [{status}]  {f.name}{rollout}")
        print(f"{'─' * 52}\n")

    # ── Helpers ──────────────────────────────────────────────

    @staticmethod
    def _hash_user(user_id: str, flag_id: str) -> int:
        """
        Stable hash → 0..99.
        Same (user_id, flag_id) pair always returns the same bucket.
        """
        key = f"{user_id}:{flag_id}".encode()
        digest = hashlib.md5(key).hexdigest()
        return int(digest[0:8], 16) % 100

    @staticmethod
    def _random_bucket() -> int:
        import random
        return random.randint(0, 99)


# ── Usage examples ────────────────────────────────────────────

if __name__ == "__main__":
    import os

    env: Environment = os.getenv("APP_ENV", "dev")  # type: ignore
    flags = FeatureFlagManager(env=env)

    # Print a full summary
    flags.summary()

    # Check a flag for a specific user
    user_id = "user_abc123"

    if flags.is_enabled("live_flight_map", user_id=user_id):
        print(f"Showing live flight map for {user_id}")

    if flags.is_enabled("weather_overlay", user_id=user_id):
        print(f"Weather overlay active for {user_id}")
    else:
        print(f"Weather overlay not yet rolled out to {user_id}")

    # Kill switch — disable without a deploy
    flags.override("live_flight_map", enabled=False)
    print(f"\nAfter kill switch — live_flight_map: {flags.is_enabled('live_flight_map')}")

    # Expand a rollout
    flags.override("weather_overlay", rollout_percentage=80)
    print(f"After expanding rollout — weather_overlay config: {flags.get_flag('weather_overlay')}")
