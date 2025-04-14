# $redis = Redis.new(host: 'localhost', port: 6379)

require 'redis'

$redis = Redis.new(url: ENV["REDIS_URL"] || "redis://localhost:6379")
