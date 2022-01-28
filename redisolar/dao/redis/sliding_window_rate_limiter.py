# Uncomment for Challenge #7
import datetime
import random
from redis.client import Redis

from redisolar.dao.base import RateLimiterDaoBase
from redisolar.dao.redis.base import RedisDaoBase
from redisolar.dao.redis.key_schema import KeySchema
# Uncomment for Challenge #7
from redisolar.dao.base import RateLimitExceededException


class SlidingWindowRateLimiter(RateLimiterDaoBase, RedisDaoBase):
    """A sliding-window rate-limiter."""
    def __init__(self,
                 window_size_ms: float,
                 max_hits: int,
                 redis_client: Redis,
                 key_schema: KeySchema = None,
                 **kwargs):
        self.window_size_ms = window_size_ms
        self.max_hits = max_hits
        super().__init__(redis_client, key_schema, **kwargs)

    def hit(self, name: str):
        """Record a hit using the rate-limiter."""
        # START Challenge #7
        p = self.redis.pipeline(transaction=True)
        curr_timestamp_ms = datetime.datetime.now().timestamp() * 1000
        key = self.key_schema.sliding_window_rate_limiter_key(name, self.window_size_ms, self.max_hits)
        p.zadd(key, {f'{curr_timestamp_ms}-{name}': curr_timestamp_ms})
        p.zremrangebyscore(key, 0.0, curr_timestamp_ms - self.window_size_ms)
        p.zcard(key)
        *_, hits = p.execute()
        if hits > self.max_hits:
            raise RateLimitExceededException()

        # END Challenge #7
