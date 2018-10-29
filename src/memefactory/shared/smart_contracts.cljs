(ns memefactory.shared.smart-contracts) 

(def smart-contracts 
{:district-config
 {:name "DistrictConfig",
  :address "0xddf5a2745ee964d1ed9330cacaf9ea2ea7e33933"},
 :ds-guard
 {:name "DSGuard",
  :address "0x74fc6891ef3c2b4d22f594fdd9dea5c9f1a123a9"},
 :param-change-registry
 {:name "ParamChangeRegistry",
  :address "0xafdb130331899f526f84fdf34a97703e8819c2c4"},
 :param-change-registry-db
 {:name "EternalDb",
  :address "0x5fba9838de80590778c1a54ad9bfe7d907b2c55a"},
 :meme-registry-db
 {:name "EternalDb",
  :address "0x78aa4a53f69ecf28a096d56cbb0b386ee7c823ac"},
 :param-change
 {:name "ParamChange",
  :address "0x4b1885c9b5a515102636b8cdd7b96a18a04e0d15"},
 :facts-db
 {:name "FactsDb",
  :address "0x360b6d00457775267aa3e3ef695583c675318c05"},
 :minime-token-factory
 {:name "MiniMeTokenFactory",
  :address "0x7182bca490d13f736184d04d411f8e3ab5e68b3b"},
 :meme-auction-factory
 {:name "MemeAuctionFactory",
  :address "0xa729ddc8c78726ce32ab23217d750b7ca15e7f30"},
 :meme-auction
 {:name "MemeAuction",
  :address "0x9b23f3a2ddd4b3fc7d38ab92e0ff9a8538fcebe6"},
 :param-change-factory
 {:name "ParamChangeFactory",
  :address "0x8204340c5c87a874614f18363d4dd1d06c81c1a2"},
 :param-change-registry-fwd
 {:name "MutableForwarder",
  :address "0xd7605729236f9368ebc948de5d5f67e656e90ade"},
 :meme-factory
 {:name "MemeFactory",
  :address "0xd656b5934cfde2647e221f56e2aba54b52cedf7b"},
 :meme-token
 {:name "MemeToken",
  :address "0x377dbbfd2dac0f02438393e0706dbb94f4c2f309"},
 :DANK
 {:name "DankToken",
  :address "0x72e322505444dcac8fddb5655e33e6eac7a361be"},
 :meme-registry
 {:name "Registry",
  :address "0x80bc878ad3403c61029518eec252c5d8c928a068"},
 :meme
 {:name "Meme", :address "0x2db5614f54013a52748b02fd70a337298d83b35e"},
 :meme-registry-fwd
 {:name "MutableForwarder",
  :address "0xa544418293a3a5492079223845cf6b2803332cbf"},
 :meme-auction-factory-fwd
 {:name "MutableForwarder",
  :address "0x4d3e05ef7f4e5e788fb334bea270a1a938b4bed3"}})