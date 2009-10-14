require 'rubygems'
require 'benchmark'
$:.push File.join(File.dirname(__FILE__), 'lib')
require 'redis/model'

n = 20000

class TestModel < Redis::Model
  value :foo
  list  :bar
end

@r = Redis.new#(:debug => true)
@r['foo'] = "The first line we sent to the server is some text"

Benchmark.bmbm do |x|
  x.report("set (model)") do
    n.times do |i|
      m = TestModel.with_key(i)
      m.foo = "The first line we sent to the server is some text";
      m.foo
    end
  end

  x.report("push+trim (model)") do
    n.times do |i|
      m = TestModel.with_key(i)
      m.bar << i
      m.bar.trim 0, 30
    end
  end
end

@r.keys('*').each do |k|
  @r.delete k
end