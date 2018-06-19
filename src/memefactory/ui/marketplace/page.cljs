(ns memefactory.ui.marketplace.page
  (:require
   [district.ui.component.page :refer [page]]
   [district.ui.graphql.subs :as gql]
   [memefactory.ui.marketplace.events :as mk-events]
   [memefactory.ui.components.app-layout :refer [app-layout]]
   [re-frame.core :refer [subscribe dispatch]]
   [reagent.core :as r]
   [react-infinite]
   [memefactory.shared.utils :as shared-utils]
   [memefactory.ui.components.tiles :as tiles]
   [district.ui.router.subs :as router-subs]
   [print.foo :refer [look] :include-macros true]))

(def react-infinite (r/adapt-react-class js/Infinite))

(defn search-tools [{:keys [:order-atom :search-atom]}]
  [:div.container
   [:div.left-section
    [:div.header
     [:img]
     [:h2 "Marketplace"]
     [:h3 "Lorem ipsum dolor..."]]
    [:div.body
     [:input {:type :text}]
     [:select
      [:option {:value "Cheapest"} "Cheapest"]]
     [:ul.tags-list
      [:li "Some Tag"]
      [:li "Another Tag"]]
     [:label "Show only cheapest offering of meme"]
     [:input {:type :checkbox}]]]
   [:div.right-section
    [:img]]])

(defn marketplace-tiles [{:keys [:search-term :order-by :order-dir]}]
  (let [build-query (fn [after]
                      [:search-meme-auctions
                       (cond-> {:first 2}
                         (not-empty search-term) (assoc :title search-term)
                         after                   (assoc :after after)
                         order-by                (assoc :order-by order-by)
                         order-dir               (assoc :order-dir order-dir))
                       [:total-count
                        :end-cursor
                        :has-next-page
                        [:items [:meme-auction/address
                                 :meme-auction/start-price
                                 :meme-auction/end-price
                                 :meme-auction/duration
                                 :meme-auction/description
                                 [:meme-auction/seller [:user/address]]
                                 [:meme-auction/meme-token
                                  [:meme-token/number
                                   [:meme-token/meme
                                    [:meme/title
                                     :meme/image-hash
                                     :meme/total-minted]]]]]]]])
        auctions-search (subscribe [::gql/query {:queries [(look (build-query nil))]}
                                    {:id :auctions-search}])]
    (fn [search-term]
      (let [all-auctions (->> @auctions-search
                              (mapcat (fn [r] (-> r :search-meme-auctions :items))))]
        (.log js/console "All auctions" all-auctions)
        [:div.tiles
         [react-infinite {:element-height 280
                          :container-height 300
                          :infinite-load-begin-edge-offset 100
                          :on-infinite-load (fn []
                                              (let [ {:keys [has-next-page end-cursor] :as r} (:search-meme-auctions (last @auctions-search))]
                                               (.log js/console "Scrolled to load more" has-next-page end-cursor)
                                               (when has-next-page
                                                 (dispatch [:district.ui.graphql.events/query
                                                            {:query {:queries [(build-query end-cursor)]}}
                                                            {:id :auctions-search}]))))}
          (doall
           (for [{:keys [:meme-auction/address] :as auc} all-auctions]
             (let [title (-> auc :meme-auction/meme-token :meme-token/meme :meme/title)]
               ^{:key address}
               [tiles/auction-tile {:on-buy-click #()} auc])))]]))))

(defmethod page :route.marketplace/index []
  (let [search-atom (r/atom {:term ""})
        order-atom (r/atom (let [{:keys [query]} @(subscribe [::router-subs/active-page])]
                             (look {:order-by (if-let [o (:order-by query)]
                                                (keyword "meme-auctions.order-by" o)
                                                :meme-auctions.order-by/started-on)
                                    :order-dir (or (keyword (:order-dir query)) :desc)})))]
    (fn []
      [app-layout
       {:meta {:title "MemeFactory"
               :description "Description"}
        :search-atom search-atom}
       [:div.marketplace
        [search-tools order-atom search-atom] 
        [marketplace-tiles {:search-term (:term @search-atom)
                            :order-by (:order-by @order-atom)
                            :order-dir (:order-dir @order-atom)}]]])))


