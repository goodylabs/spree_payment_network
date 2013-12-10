Spree::Core::Engine.routes.prepend do
  match '/sofort/payment_network_callback', to: "checkout#payment_network_callback", via: [:get]
end
