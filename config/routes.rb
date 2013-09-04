Spree::Core::Engine.routes.append do
  match '/sofort/payment_network_callback' => 'checkout#payment_network_callback', :method => :get
end
