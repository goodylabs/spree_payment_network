Spree::CheckoutController.class_eval do
  before_filter :redirect_to_payment_network_form_if_needed, :only => [:update]
  
  before_filter :load_sofort_order, :only => [:payment_network_callback]

  skip_before_filter :verify_authenticity_token, :only => [:payment_network_callback]
  
  def redirect_to_payment_network_form_if_needed

    if !params[:order][:coupon_code].blank?
      logger.info "=====> redirect_to_payment_network_form_if_needed false - skipping... "
      return
    end

    logger.info "=====> redirect_to_payment_network_form_if_needed ... @order: #{@order.inspect}"
    if !@order.nil? && !@order.payments.nil? && @order.payments.size > 0

      payment_method = Spree::PaymentMethod.find(@order.payments.first[:payment_method_id])

      if payment_method.kind_of?(Spree::PaymentMethod::PaymentNetwork)

        logger.info "=====> redirect_to_payment_network_form_if_needed for Spree::PaymentMethod::PaymentNetwork..."
        confirmation_step_present = current_order.confirmation_required?
        logger.info "=====> confirmation_step_present: #{confirmation_step_present} ..."
        if !confirmation_step_present && params[:state] == "payment"
          logger.info "=====> [ payment ]confirmation_step_present: #{params[:state]} #{params[:order][:payments_attributes]} ..."
          return unless params[:order][:payments_attributes]
          if params[:order][:coupon_code]
            @order.update_attributes(object_params)
            fire_event('spree.checkout.coupon_code_added', :coupon_code => @order.coupon_code)
          end
          load_order
          payment_method = Spree::PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])
        elsif confirmation_step_present && params[:state] == "confirm"
          logger.info "=====> [ confirm ] confirmation_step_present: #{params[:state]} ..."
          logger.info "=====> payment_method: #{payment_method.inspect}"
          load_order
          logger.info "=====> order: #{@order.inspect} ..."
          payment_method = @order.pending_payments.select{ |p| p.payment_method.kind_of?(Spree::PaymentMethod::PaymentNetwork)}.first.payment_method
          logger.info "=====> payment_method: #{payment_method.inspect} ..."
        end

        logger.info "=====> payment_method: #{payment_method.inspect} , params[:state]: #{params[:state]}..."

        if !payment_method.nil? && payment_method.kind_of?(Spree::PaymentMethod::PaymentNetwork) && params[:state] == "confirm"
          redirect_to "#{payment_method.server_url}?user_id=#{payment_method.preferred_user_id}&project_id=#{payment_method.preferred_project_id}&amount=#{@order.total}&reason_1=#{@order.number}&user_variable_0=#{payment_method.id}&user_variable_1=#{@order.id}&hash=#{payment_method.hash_value({:amount => @order.total, :reason_1 => @order.number, :user_variable_1 => @order.id})}"
        end
      end

    end

  end
  
  def payment_network_callback
    logger.info "===> payment_network_callback ..."
    
    if @order && params[:status] == 'success'
      logger.info "===> payment_network_callback success ..."
      gateway = Spree::PaymentMethod.find(params[:payment_method_id])

      @order.payments.clear
      payment = @order.payments.create
      payment.started_processing
      payment.amount = @order.total
      payment.payment_method = gateway
      payment.complete
      logger.info "===> payment completed ..."
      @order.save
      @order.finalize!

      @order.state = 'complete'
      @order.shipment_state = 'ready'
      @order.save!

      flash[:notice] = I18n.t(:order_processed_successfully)
      redirect_to completion_route
    else
      redirect_to checkout_state_path(@order.state)
    end
  end

  def load_sofort_order 
    logger.info "Load SOFORT order"
    @order = Spree::Order.find(params[:order_id])
  end

end
