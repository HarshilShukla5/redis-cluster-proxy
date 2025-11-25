setup &RedisProxyTestCase::GenericSetup

test "pubsub delivers messages" do
    sub = Redis.new(port: @proxy.port)
    received = []
    t = Thread.new do
        sub.subscribe("proxy:test:channel") do |on|
            on.message do |channel, msg|
                received << [channel, msg]
                sub.unsubscribe if received.length >= 2
            end
        end
    end
    sleep 0.25
    @proxy.publish("proxy:test:channel", "hello")
    @proxy.publish("proxy:test:channel", "world")
    t.join(5)
    assert_equal([%w(proxy:test:channel hello),
                  %w(proxy:test:channel world)], received)
end

test "pubsub unsubscribe clears state" do
    sub = Redis.new(port: @proxy.port)
    unsubscribed = false
    t = Thread.new do
        sub.subscribe("proxy:test:once") do |on|
            on.message do |_channel, _msg|
                sub.unsubscribe
            end
            on.unsubscribe do |_channel, _count|
                unsubscribed = true
            end
        end
    end
    sleep 0.25
    @proxy.publish("proxy:test:once", "payload")
    t.join(5)
    assert(unsubscribed, "expected unsubscribe callback to fire")
end
