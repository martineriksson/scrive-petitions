
class ScrivePetitions < Sinatra::Application

  get ('/') { haml :home }

  #get ('/create') { haml :create }

  post ('/create') do
    @petition = Petition.create(
      params[:title],
      Base64.encode64(params[:file][:tempfile].read)
    )
    redirect "/#{@petition.document_id}"
  end

  get '/:petition' do
    @petition = Petition.find params[:petition]
    pass unless @petition
    @show = true
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

  # First of all, we need to know some things about the API.
  #
  API = { :url       => "http://petitions-devel.scrive.com/integration/api/",
          :embed_url => "https://petitions-devel.scrive.com",
          :service   => "test_service",
          :password  => "test_service" }

  # This is the local document 'database', a list of Petition objects.
  #
  @@all = []
  
  # Basic attributes of Petition objects. Here we make them available as instance variables with getter and setter methods.
  #
  attr_accessor :document_id,
                :title,
                :slug,
                :body,            # What is this?
                :pdf,             # PDF-file, Base64 encoded.
                :responsible,     # The entity being petitioned, email given by creator.
                :signers          # a list of

  # To create a petition object, pass a hash with its attributes.
  #
  def initialize attrs
    attrs.each_pair { |a, v| send("#{a}=", v) }
    @@all << self
  end
  
  # To determine who is the creator and owner of a petition, we find out who signed it first.
  #
  def creator
    #signers.sort{ |a,b| b.date <=> a.date }.first
  end

  def signers
    Signer.fetch document_id
  end
  
  def delete
    response = RestClient.post( "#{API[:url]}remove_document",
                                'service' => API[:service],
                                'password' => API[:password],
                                'body' => { "document_id" => document_id, }.to_json
                              )
    puts "Deleted something? #{response.inspect}"
    @@all.delete self
  end
  
  class << self
    
    # This is how we create new petitions.
    #
    def create title, filedata
      filedata.gsub! "\n", ""
      response = RestClient.post( "#{API[:url]}new_document",
                                  'service' => API[:service],
                                  'password' => API[:password],
                                  'body' => { "company_id" => '0',
                                              "title"      => title,
                                              "type"       => 10,
                                              "files"      => [{
                                                :name => title,
                                                #:content => Base64.encode64(open('test-petition.pdf').read),
                                                :content => filedata,
                                              }]
                                            }.to_json
                                )

      #puts response
      
      document_id = JSON.parse(response)['document_id']
      
      #first_signer = 

      Petition.new({
        :document_id => document_id,
        :title => title,
        #:slug => slugify(title),
        :pdf => filedata,
        #:signers => [first_signer],
      })
    end

    # Fetch all petitions (documents) from the Scrive API
    #
    def all
      fetch_all_petitions
      @@all
    end
    
    # This is our basic way of knowing what petitions there are,
    # we call 'documents' in the API.
    #
    def fetch_all_petitions
      response = RestClient.post( "#{API[:url]}documents",
                                  'service' => API[:service],
                                  'password' => API[:password],
                                  #'body' => { 'company_id' => '0' }.to_json )
                                  'body' => {}.to_json )

      raise "Could not retreive documents from API!" unless response

      #puts response

      petitions = JSON.parse(response)['documents']
      petitions ||= []

      created = petitions.map do |petition|
        unless find petition['document_id']
          Petition.new({
            :document_id => petition['document_id'],
            :title => petition['title'],
          })
        end
      end
    end

    def find document_id
      @@all.select{ |p| p.document_id == document_id }.first
    end
    
    # Only run this if you are crazy:
    #
    def kill_em_all!
      all.each { |p| p.delete }
    end

  end

  # Get an embeddable frame from the API.
  #
  def embed email
    response = RestClient.post( "#{API[:url]}embed_document_frame",
                                'service' => API[:service],
                                'password' => API[:password],
                                'body' => { "document_id" => document_id,
                                            "email"       => "petitions@example.org",
                                            "location"    => "http:/scrive-petitions.heroku.com/#{slug}"
                                          }.to_json
                              )
    raise "Could not retreive embed_frame from API!" unless response

    JSON.parse(response)['link'] + "sign"
  end

  class Signer
    attr_accessor :name, :email, :date

    def initialize hash_from_api
      @name  = "#{hash_from_api['fstname']} #{hash_from_api['sndname']}"
      @email = hash_from_api['email']
      @date  = hash_from_api['sign']
    end

    def self.fetch document_id
      response = RestClient.post( "#{API[:url]}document",
                                  'service' => API[:service],
                                  'password' => API[:password],
                                  'body' => { "document_id" => document_id, }.to_json )

      JSON.parse(response)['document']['involved'].map { |s| Signer.new s }
    end
  end

end

#Petition.kill_em_all!