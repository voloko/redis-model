require "redis"
require "json"

# Simple models for redis-rb.
# It maps ruby properties to <tt>model_name:id:field_name</tt> keys in redis.
# It also adds marshaling for string fields and more OOP style access for sets and lists
#
# == Define
#   
#   require 'redis/model'
#   class User < Redis::Model
#     value :name,     :string
#     value :created,  :datetime
#     value :profile,  :json
#     list  :posts
#     set   :followers
#   end
#
# See Redis::Marshal for more types
#
#
# == Write
# 
#   u = User.with_key(1)
#   u.name = 'Joe'               # set user:1:name Joe
#   u.created = DateTime.now     # set user:1:created 2009-10-05T12:09:56+0400
#   u.profile = {                # set user:1:profile {"sex":"M","about":"Lorem","age":23}
#     :age => 23,                
#     :sex => 'M',               
#     :about => 'Lorem'          
#   }                            
#   u.posts << "Hello world!"    # rpush user:1:posts 'Hello world!'
#   u.followers << 2             # sadd user:1:followers 2
#
# == Read
#
#   u = User.with_key(1)
#   p u.name                            # get user:1:name
#   p u.created.strftime('%m/%d/%Y')    # get user:1:created
#   p u.posts[0,20]                     # lrange user:1:posts 0 20
#   p u.followers.has_key?(2)           # sismember user:1:followers 2
#


class Redis::Model
  attr_accessor :id
  
  def initialize(id)
    self.id = id
  end
  
  def redis #:nodoc:
    self.class.redis
  end
  
  # Issues delete commands for all defined fields
  def delete(name = nil)
    if name
      redis.delete field_key(name.to_s)
    else
      self.class.fields.each do |field|
        redis.delete field_key(field[:name])
      end
    end
  end
  
protected
  def prefix #:nodoc:
    @prefix ||= self.class.prefix
  end

  def field_key(name) #:nodoc:
    "#{prefix}:#{id}:#{name}"
  end
  
  class << self
    # Defaults to model_name.dasherize
    attr_accessor :prefix
    
    def prefix
      self.class.to_s.
        sub(%r{(.*::)}, '').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        downcase
    end
  
    # Creates new model instance with new uniqid
    # NOTE: "sequence:model_name:id" key is used
    def create(values = {})
      populate_model(self.new(next_id))
    end
  
    # Creates new model instance with given id
    alias_method :with_key, :new
    alias_method :with_next_key, :create
  
    # Defines marshaled rw accessor for redis string value
    def field(name, type = :string)
      class_name = marshal_class_name(name, type)
      
      fields << {:name => name.to_s, :type => :type}
      if type == :string
        class_eval "def #{name}; @#{name} ||= redis[field_key('#{name}')]; end"
        class_eval "def #{name}=(value); @#{name} = redis[field_key('#{name}')] = value; end"
      else
        class_eval "def #{name}; @#{name} ||= Marshal::#{class_name}.load(redis[field_key('#{name}')]); end"
        class_eval "def #{name}=(value); @#{name} = value; redis[field_key('#{name}')] = Marshal::#{class_name}.dump(value) end"
      end
    end
    alias_method :value, :field
  
    # Defines accessor for redis list
    def list(name, type = :string)
      class_name = marshal_class_name(name, type)
      
      fields << {:name => name.to_s, :type => :list}
      class_eval "def #{name}; @#{name} ||= ListProxy.new(self.redis, field_key('#{name}'), Marshal::#{class_name}); end"
      eval_writer(name)
    end
  
    # Defines accessor for redis set
    def set(name, type = :string)
      class_name = marshal_class_name(name, type)
      
      fields << {:name => name.to_s, :type => :set}
      class_eval "def #{name}; @#{name} ||= SetProxy.new(self.redis, field_key('#{name}'), Marshal::#{class_name}); end"
      eval_writer(name)
    end
    
    def marshal_class_name(name, type)
      Marshal::TYPES[type] or raise ArgumentError.new("Unknown type #{type} for field #{name}")
    end
  
    # Redefine this to change connection options
    def redis
      @@redis ||= Redis.new
    end
    
    def fields #:nodoc:
      @fields ||= []
    end

  protected
    def eval_writer(name) #:nodoc:
      class_eval <<-END
        def #{name}=(value) 
          field = self.#{name}; 
          if value.respond_to?(:each)
            value.each {|v| field << v}
          else
            field << v
          end
        end
      END
    end
  
    def next_id #:nodoc:
      redis.incr "sequence:#{prefix}:id"
    end
  
    def populate_model(model, values) #:nodoc:
      return model if values.empty?
      @@fields.each do |field|
        model.send(:"#{field[:name]}=", value) if values.has_key?(field[:name])
      end
      model
    end
  end
  
  module Marshal
    TYPES = {
      :string   => 'String',
      :int      => 'Integer',
      :integer  => 'Integer',
      :float    => 'Float',
      :datetime => 'DateTime',
      :json     => 'JSON',
    }

    class String
      def self.dump(v)
        v
      end

      def self.load(v)
        v
      end
    end

    class Integer
      def self.dump(v)
        v.to_s
      end

      def self.load(v)
        v && v.to_i
      end
    end

    class Float
      def self.dump(v)
        v.to_s
      end

      def self.load(v)
        v && v.to_f
      end
    end

    class DateTime
      def self.dump(v)
        v.strftime('%FT%T%z')
      end

      def self.load(v)
        v && ::DateTime.strptime(v, '%FT%T%z')
      end
    end

    class JSON
      def self.dump(v)
        ::JSON.dump(v)
      end

      def self.load(v)
        v && ::JSON.load(v)
      end
    end
  end
  
  
  
  class FieldProxy #:nodoc
    def initialize(redis, name, marshal)
      @redis   = redis
      @name    = name
      @marshal = marshal
    end

    def method_missing(method, *argv)
      translated_method = translate_method_name(method)
      raise NoMethodError.new("Method '#{method}' is not defined") unless translated_method
      @redis.send translated_method, @name, *argv
    end

    protected
      def translate_method_name(m)
        m
      end
  end



  class ListProxy < FieldProxy #:nodoc:
    def <<(v)
      @redis.rpush @name, @marshal.dump(v)
    end
    alias_method :push_tail, :<<
    
    def push_head(v)
      @redis.lpush @name, @marshal.dump(v)
    end
    
    def pop_tail
      @marshal.load(@redis.rpop(@name))
    end
    
    def pop_head
      @marshal.load(@redis.lpop(@name))
    end
    
    def [](from, to = nil)
      if to.nil?
        @marshal.load(@redis.lindex(@name, from))
      else
        @redis.lrange(@name, from, to).map! { |v| @marshal.load(v) }
      end
    end
    alias_method :range, :[]
    
    def []=(index, v)
      @redis.lset(@name, index, @marshal.dump(v))
    end
    alias_method :set, :[]=
    
    def include?(v)
      @redis.exists(@name, @marshal.dump(v))
    end
    
    def remove(count, v)
      @redis.lrem(@name, count, @marshal.dump(v))
    end
    
    def length
      @redis.llen(@name)
    end
    
    def trim(from, to)
      @redis.ltrim(@name, from, to)
    end
    
    def to_s
      range(0, 100).join(', ')
    end

  protected
    def translate_method_name(m)
      COMMANDS[m]
    end
  end



  class SetProxy < FieldProxy #:nodoc:
    COMMANDS = {
      :intersect_store  => "sinterstore",
      :union_store      => "sunionstore",
      :diff_store       => "sdiffstore",
      :move             => "smove",
    }
    
    def <<(v)
      @redis.sadd @name, @marshal.dump(v)
    end
    alias_method :add, :<<
    
    def delete(v)
      @redis.srem @name, @marshal.dump(v)
    end
    alias_method :remove, :delete
    
    def include?(v)
      @redis.sismember @name, @marshal.dump(v)
    end
    alias_method :has_key?, :include?
    alias_method :member?, :include?
    
    def members
      @redis.smembers(@name).map { |v| @marshal.load(v) }
    end
    
    def intersect(*keys)
      @redis.sinter(@name, *keys).map { |v| @marshal.load(v) }
    end
    
    def union(*keys)
      @redis.sunion(@name, *keys).map { |v| @marshal.load(v) }
    end
    
    def diff(*keys)
      @redis.sdiff(@name, *keys).map { |v| @marshal.load(v) }
    end
    
    def length
      @redis.llen(@name)
    end
    
    def to_s
      members.join(', ')
    end

  protected
    def translate_method_name(m)
      COMMANDS[m]
    end
  end
  
  
end

