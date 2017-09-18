require 'sinatra'
require 'capybara/poltergeist'
require 'json'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new app, js_errors: false
end
Capybara.javascript_driver = :poltergeist

get '/' do
  session = Capybara::Session.new :poltergeist
  session.visit 'https://www.optus.com.au/my-account-login'
  session.fill_in 'user', with: ENV.fetch("USERNAME")
  session.fill_in 'password', with: ENV.fetch("PASSWORD")
  session.click_button 'Log in'

  sleep 3
  session.visit "https://www.optus.com.au/mcssapi/rp-webapp-9-common" +
    "/ebill/customer/#{ENV.fetch("CUSTOMER_ID")}" +
    "/shared-unbilled-usage-accumulators" +
    "?account=#{ENV.fetch("ACCOUNT_ID")}" +
    "&subscription=#{ENV.fetch("SUBSCRIPTION_ID")}"

  data = JSON.parse(session.html.scan(/{.*}/).first)
  plan = data
    .dig("ImplSharedUnbilledUsageRestOutput", "implAgreementSharedUsageInfo")[0]
    .dig("sharedUnbilledUsageAccumulators")[1]
    .dig("accumulators")
    .last

  content_type :json
  {
    quota: plan["quota"],
    remaining: plan["remainingQuota"],
    used: plan["volume"],
    used_percentage: plan["volume"] / plan["quota"]
  }.to_json
end
