require 'rubygems'
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'redis/model'


class User < Redis::Model
  value :name,      :string
  value :created,   :datetime
  value :profile,   :json
  
  list  :posts,     :json
  
  set   :followers, :int
end



u = User.with_key(1)
u.delete
u.name = 'Joe'                    
u.created = DateTime.now          
u.profile = {                     
  :age => 23,                     
  :sex => 'M',                    
  :about => 'Lorem'               
}                                 
u.posts << {                      
    :title => "Hello world!",     
    :text  => "lorem"             
}                                 
u.followers << 2                  
                                  
                                  
                                  
u = User.with_key(1)  
p u.name                          
p u.created.strftime('%m/%d/%Y')  
p u.posts[0,20]                   
p u.posts[0]                      
p u.followers.has_key?(2)         
