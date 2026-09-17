# db/seeds.rb

products = [
  {
    title: "Merino Wool Scarf",
    sku: "SCF-001",
    description: "A soft, cozy scarf made from 100% merino wool. Perfect for staying warm on cold winter days while looking effortlessly stylish.",
    price_cents: 3500,
    stock_quantity: 40
  },
  {
    title: "Stainless Steel French Press",
    sku: "KIT-002",
    description: "Brew rich, full-bodied coffee at home with this durable stainless steel french press. Holds up to four cups and is built to last for years.",
    price_cents: 4200,
    stock_quantity: 25
  },
  {
    title: "Wireless Noise-Cancelling Headphones",
    sku: "ELC-003",
    description: "Immerse yourself in your music with active noise cancellation and up to 30 hours of battery life. Comfortable over-ear design for all-day listening.",
    price_cents: 12999,
    stock_quantity: 15
  },
  {
    title: "Cast Iron Camping Skillet",
    sku: "OUT-004",
    description: "A rugged cast iron skillet built for the outdoors. Great for cooking over an open fire or campstove during weekend hiking and camping trips.",
    price_cents: 2800,
    stock_quantity: 30
  },
  {
    title: "Cotton Knit Beanie",
    sku: "CLT-005",
    description: "A lightweight knit beanie made from soft cotton blend fabric. Ideal for chilly mornings, layering, or casual everyday wear.",
    price_cents: 1500,
    stock_quantity: 60
  },
  {
    title: "Portable Bluetooth Speaker",
    sku: "ELC-006",
    description: "Take your music anywhere with this compact, waterproof Bluetooth speaker. Delivers surprisingly powerful sound for its size, perfect for outdoor gatherings.",
    price_cents: 4500,
    stock_quantity: 20
  },
  {
    title: "Insulated Travel Mug",
    sku: "KIT-007",
    description: "Keep your coffee or tea hot for hours with this double-walled insulated travel mug. Leak-proof lid makes it ideal for commuting or road trips.",
    price_cents: 1800,
    stock_quantity: 50
  },
  {
    title: "Hiking Backpack 40L",
    sku: "OUT-008",
    description: "A spacious and durable backpack designed for multi-day hikes. Features padded straps, a hydration sleeve, and multiple compartments for gear organization.",
    price_cents: 8900,
    stock_quantity: 18
  },
  {
    title: "Fleece Zip-Up Jacket",
    sku: "CLT-009",
    description: "A warm, breathable fleece jacket perfect for layering during outdoor activities or lounging at home on a cold evening.",
    price_cents: 5500,
    stock_quantity: 35
  },
  {
    title: "Smart LED Desk Lamp",
    sku: "ELC-010",
    description: "An adjustable desk lamp with customizable brightness and color temperature. Controlled via app or voice assistant for a modern, tech-forward workspace.",
    price_cents: 3999,
    stock_quantity: 22
  }
]

products.each do |attrs|
  Product.find_or_create_by!(sku: attrs[:sku]) do |product|
    product.title = attrs[:title]
    product.description = attrs[:description]
    product.price_cents = attrs[:price_cents]
    product.stock_quantity = attrs[:stock_quantity]
  end
end

puts "Seeded #{Product.count} products."
