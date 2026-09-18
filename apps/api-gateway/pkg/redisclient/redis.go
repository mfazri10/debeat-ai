package redisclient

import (
	"context"
	"time"

	"github.com/redis/go-redis/v9"
)

type Client struct {
	Rdb *redis.Client
}

func New(redisURL string) *Client {
	opt, err := redis.ParseURL(redisURL)
	if err != nil {
		// Fallback default
		opt = &redis.Options{
			Addr: "localhost:6379",
		}
	}

	rdb := redis.NewClient(opt)
	return &Client{Rdb: rdb}
}

func (c *Client) Ping(ctx context.Context) error {
	return c.Rdb.Ping(ctx).Err()
}

func (c *Client) Close() error {
	if c.Rdb != nil {
		return c.Rdb.Close()
	}
	return nil
}

func (c *Client) Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error {
	return c.Rdb.Set(ctx, key, value, expiration).Err()
}

func (c *Client) Get(ctx context.Context, key string) (string, error) {
	return c.Rdb.Get(ctx, key).Result()
}
