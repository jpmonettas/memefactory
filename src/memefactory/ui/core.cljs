(ns memefactory.ui.core
  (:require
    [cljs.spec.alpha :as s]
    [clojure.string :as str]
    [district.ui.component.router :refer [router]]
    [district.ui.graphql]
    [district.ui.notification]
    [district.ui.now]
    [district.ui.reagent-render]
    [district.ui.router-google-analytics]
    [district.ui.router]
    [district.ui.smart-contracts]
    [district.ui.web3-account-balances]
    [district.ui.web3-accounts]
    [district.ui.web3-balances]
    [district.ui.web3-tx-id]
    [district.ui.web3-tx-log]
    [district.ui.web3-tx]
    [district.ui.web3]
    [district.ui.window-size]
    [memefactory.shared.graphql-schema :refer [graphql-schema]]
    [memefactory.shared.routes :refer [routes]]
    [memefactory.shared.smart-contracts :refer [smart-contracts]]
    [memefactory.ui.home.page]
    [mount.core :as mount]
    [print.foo :include-macros true]))

(def debug? ^boolean js/goog.DEBUG)

(def skipped-contracts [:ds-guard :param-change-registry-db :meme-registry-db :minime-token-factory])

(defn ^:export init []
  (s/check-asserts debug?)
  (enable-console-print!)
  (-> (mount/with-args
        {:web3 {:url "http://localhost:8549"}
         :smart-contracts {:contracts (apply dissoc smart-contracts skipped-contracts)}
         :web3-balances {:contracts (select-keys smart-contracts [:DANK])}
         :web3-tx-log {:open-on-tx-hash? true
                       :tx-costs-currencies [:USD]}
         :reagent-render {:id "app"
                          :component-var #'router}
         :router {:routes routes
                  :default-route :route/home}
         :router-google-analytics {:enabled? (not debug?)}
         :graphql {:schema graphql-schema
                   :url "http://localhost:6300/graphql"}})
    (mount/start)))