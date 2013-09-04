# encoding: UTF-8
module Spree
  class PaymentMethod::PaymentNetwork < PaymentMethod
    preference :project_id, :string
    preference :user_id, :string
    preference :project_password, :string
    preference :button_text, :string, :default => 'Mit sofortüberweisung bezahlen'

    attr_accessible :preferred_project_id, :preferred_project_password, :preferred_user_id, :preferred_button_text

    def server_url
      "https://www.sofortueberweisung.de/payment/start"
    end

    def hash_value(options = {})
      data = ActiveSupport::OrderedHash.new
      data[:user_id] = preferred_user_id
      data[:project_id] = preferred_project_id
      data[:sender_holer] = ''
      data[:sender_account_number] = ''
      data[:sender_bank_code] = ''
      data[:sender_country_id] = ''
      data[:amount] = ''
      data[:currency_id] = 'EUR'
      data[:reason_1] = ''
      data[:reason_2] = ''
      data[:user_variable_0] = id
      data[:user_variable_1] = ''
      data[:user_variable_2] = ''
      data[:user_variable_3] = ''
      data[:user_variable_4] = ''
      data[:user_variable_5] = ''
      data[:project_password] = preferred_project_password
      data.merge!(options)

      Digest::SHA512.hexdigest(data.values.join('|'))
    end

    def purchase(money, credit_card_or_referenced_id, options = {})

      puts "****************"
      puts credit_card_or_referenced_id.inspect

      payment = Spree::Payment.find_by_source_id(credit_card_or_referenced_id)
      errors.add(:payment, "couldn't find corresponding payment") if payment.nil?

      puts "****************"
      puts payment.response_code.inspect


      if payment.response_code.present?
        response = provider.capture(money,payment.response_code, options)
      end

      response
    end

  end
end
