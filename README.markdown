## redis-model

Minimal model support for [redis-rb](http://github.com/ezmobius/redis-rb). 
Directly maps ruby properties to `model_name:id:field_name` keys in redis. 
Scalar, list and set properties are supported.

Values can be marshaled to/from `Integer`, `Float`, `DateTime`, `JSON`. See `Redis::Model::Marshal` for more info.

### Define

    require 'redis/model'
    
    class User < Redis::Model
      value :name,      :string
      value :created,   :datetime
      value :profile,   :json
      
      list  :posts,     :json
      
      set   :followers, :int
    end

### Write

    u = User.with_key(1)
    u.name = 'Joe'                      # set user:1:name Joe
    u.created = DateTime.now            # set user:1:created 2009-10-05T12:09:56+0400
    u.profile = {                       # set user:1:profile {"sex":"M","about":"Lorem","age":23}
      :age => 23,                       
      :sex => 'M',                      
      :about => 'Lorem'                 
    }                                   
    u.posts << {                        # rpush user:1:posts {"title":"Hello world!","text":"lorem"}
        :title => "Hello world!",
        :text  => "lorem"
    }           
    u.followers << 2                    # sadd user:1:followers 2

### Read

    u = User.with_key(1)
    p u.name                            # get user:1:name
    p u.created.strftime('%m/%d/%Y')    # get user:1:created
    p u.posts[0,20]                     # lrange user:1:posts 0 20
    p u.posts[0]                        # lindex user:1:posts 0
    p u.followers.has_key?(2)           # sismember user:1:followers 2
