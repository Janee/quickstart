require 'base64'
require 'date'
require 'json'
require 'belvo'
require 'sinatra'
require 'sinatra/cross_origin'

# Fill in your Belvo API keys - https://dashboard.belvo.com
BELVO_SECRET_ID = ENV['BELVO_SECRET_ID']
BELVO_SECRET_PASSWORD = ENV['BELVO_SECRET_PASSWORD']
# Use `sandbox` to test with Belvo's Sandbox environment
# Use `production` to go live
# Use `development` to test with real data
BELVO_ENV = ENV['BELVO_ENV']
# Widget branding variables
COMPANY_ICON_URL = ENV['COMPANY_ICON_URL']
COMPANY_LOGO_URL = ENV['COMPANY_LOGO_URL']
COMPANY_NAME = ENV['COMPANY_NAME']
COMPANY_BENEFIT_HEADER = ENV['COMPANY_BENEFIT_HEADER']
COMPANY_BENEFIT_CONTENT = ENV['COMPANY_BENEFIT_CONTENT']
COMPANY_OPPORTUNITY_LOSS = ENV['COMPANY_OPPORTUNITY_LOSS']

if BELVO_ENV == 'production'
  BELVO_ENV_URL = 'https://api.belvo.com'
elsif BELVO_ENV == 'development'
  BELVO_ENV_URL = 'https://development.belvo.com'
else
  BELVO_ENV_URL = 'https://sandbox.belvo.com'
end

set :port, 5000
set :bind, '0.0.0.0'
  configure do
    enable :cross_origin
  end
  before do
    response.headers['Access-Control-Allow-Origin'] = '*'
  end

options "*" do
  response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
  response.headers['Access-Control-Allow-Origin'] = '*'

  200
end

belvo = Belvo::Client.new(
  BELVO_SECRET_ID,
  BELVO_SECRET_PASSWORD,
  BELVO_ENV_URL
)


before do
  if request.body
    request.body.rewind
    @request_payload = JSON.parse(request.body.read.to_json)
  end
end


# Request an access token to be used when loading the Widget
# https://developers.belvo.co/docs/connect-widget#section--3-generate-an-access_token-
get '/get_token' do
  widget = {
      branding: {
        company_icon: COMPANY_ICON_URL,
        company_logo: COMPANY_LOGO_URL,
        company_name: COMPANY_NAME,
        company_benefit_header: COMPANY_BENEFIT_HEADER,
        company_benefit_content: COMPANY_BENEFIT_CONTENT,
        opportunity_loss: COMPANY_OPPORTUNITY_LOSS
      }
  }
  options = { scopes: 'read_institutions,write_links,read_links', widget: widget }
  response = belvo.widget_token.create(options: options)
  pretty_print_response(response)
  content_type :json
  response.to_json
end

post '/accounts' do
  link_id = JSON.parse(@request_payload)['link_id']

  response = belvo.accounts.retrieve link: link_id
  pretty_print_response(response)
  content_type :json
  response.to_json
end

post '/transactions' do
  link_id = JSON.parse(@request_payload)['link_id']

  response = belvo.transactions.retrieve(
    link: link_id,
    date_from: (Date.today - 30),
    options: { "date_to": Date.today}
  )
  pretty_print_response(response)
  content_type :json
  response.to_json
end

post '/balances' do
  link_id = JSON.parse(@request_payload)['link_id']

  response = belvo.balances.retrieve(
    link: link_id,
    date_from: (Date.today - 30),
    options: { "date_to": Date.today}
  )
  pretty_print_response(response)
  content_type :json
  response.to_json
end

post '/owners' do
  link_id = JSON.parse(@request_payload)['link_id']

  response = belvo.owners.retrieve(
    link: link_id
  )
  pretty_print_response(response)
  content_type :json
  response.to_json
end

post '/statements' do
  response = belvo.statements.retrieve(
    link: params['link_id'],
    account: params['account-id'],
    year: params['year'],
    month: params['month']
  )
  pretty_print_response(response)
  content_type :json
  response.to_json
end


def format_error(err)
  { error: {
      error_code: err.error_code,
      error_message: err.error_message,
      error_type: err.error_type
    }
  }
end

def pretty_print_response(response)
  puts JSON.pretty_generate(response)
end
