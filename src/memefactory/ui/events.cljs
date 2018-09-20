(ns memefactory.ui.events
  (:require [cljsjs.buffer]
            [memefactory.ui.contract.registry-entry :as registry-entry]
            [print.foo :refer [look] :include-macros true]
            [re-frame.core :as re-frame]
            [ajax.core :as ajax]
            [goog.string :as gstring]
            [graphql-query.core :refer [graphql-query]]))

(defn- build-challenge-meta-string [{:keys [comment] :as data}]
  (-> {:comment comment}
      clj->js
      js/JSON.stringify))

;; Adds the challenge to ipfs and if successfull dispatches ::create-challenge
(re-frame/reg-event-fx
 ::add-challenge
 (fn [{:keys [db]} [_ {:keys [:reg-entry/address :comment] :as data}]]
   (let [challenge-meta (build-challenge-meta-string {:comment comment})
         buffer-data (js/buffer.Buffer.from challenge-meta)]
     (prn "Uploading challenge meta " challenge-meta)
     {:ipfs/call {:func "add"
                  :args [buffer-data]
                  :on-success [::registry-entry/approve-and-create-challenge data]
                  :on-error ::error}})))


(re-frame/reg-event-fx
 ::send-phone-code
 (fn [{:keys [db]} [_ phone-number code]]
   (look {:http-xhrio {:method          :post
                       :uri             "http://localhost:6300/graphql"
                       :params          {:query (gstring/format "mutation {sendPhoneCode(phoneNumber:\"%s\", code:\"%s\")}"
                                                                phone-number
                                                                code)}
                       :timeout         8000
                       :response-format (ajax/json-response-format {:keywords? true})
                       :format          (ajax/json-request-format)
                       :on-success      [::send-phone-code-success]
                       :on-failure      [::send-phone-code-error]}})))

(re-frame/reg-event-db
 ::send-phone-code-success
 (fn [db [_ data]]
   ;; TODO add twilio level errors here
   db))

(re-frame/reg-event-db
 ::send-phone-code-error
 (fn [db [_ data]]
   ;; TODO add http level errors here
   db))
