
class ScrivePetitions < Sinatra::Application

  get ('/') { haml :home }

  get ('/create') { haml :create }

  get '/:petition' do
    @petition = Petition.find params[:petition]
    pass unless @petition
    haml :show
  end  

  get '/css/style.css' do
    content_type 'text/css', :charset  => 'utf-8'
    sass :style
  end

end


## Dummy models
###############################################################################

class Petition
  
  attr_accessor :title,
                :body,
                :slug,
                :creator,
                :responsible,
                :signers
  
  def initialize attrs
    attrs.each_pair { |a, v| send("#{a}=", v) }
  end

  class << self

    def all
      [find(nil)]
    end

    def find id_or_name
      Petition.new({
        :title => 'Resign, Mr Bildt!',
        :body => 'Enough of oil corruption! The only decent thing is for the Foreign Minister to resign!',
        :slug => 'resign-mr-bildt',
        :creator => 'martin@artilect.com',
        :responsible => 'carl.bildt@foreign.ministry.se',
        :signers => (rand(4) + 2).times.inject([]) {  |a, i| a << User.find },
      })
    end

  end

end

class User

  attr_accessor :name,
                :email
  
  def initialize attrs
    attrs.each_pair { |a, v| send("#{a}=", v) }
  end

  def self.find id_or_name=nil
    User.new({
      :name => "Rutger Forbnitz",
      :email => "rutger@forbnitz.org",
    })
  end
end
