(ns memefactory.styles.component.buttons
  (:require [garden.def :refer [defstyles]]
            [garden.stylesheet :refer [at-media]]
            [clojure.string :as s]
            [memefactory.styles.base.icons :refer [icons]]
            [memefactory.styles.base.borders :refer [border-top]]
            [memefactory.styles.base.colors :as c]
            [memefactory.styles.base.fonts :refer [font]]
            [memefactory.styles.base.media :refer [for-media-min for-media-max]]
            [garden.selectors :as sel]
            [garden.units :refer [pt px em rem]]
            [clojure.string :as str]))

(defn button [{:keys [color background-color before-icon after-icon width height]}]
  [:&
   (font :bungee)
   {:border-radius (em 2)
    :display "block"
    :bottom (em 2)
    :height (or height (em 2))
    :width (or width (em 8))
    :border-style "none"
    :color (c/color color)
    :background-color (c/color background-color)}])


(defn get-dank-button []
  [:&
   (font :bungee)
   {:position :relative
    ;; :bottom (em -2)
    ;; :top (em -2)
    :top (em 0)
    :height (em 4)
    :line-height (em 4)
    :right (px 0)
    :display :block
    :color (c/color :white)
    :background (str "url('/assets/icons/gears-button-bg-l.png') left 1em center / 40% 60% no-repeat,"
                     "url('/assets/icons/gears-button-bg-r.png') right 1em center / 40% 60% no-repeat "

                     (c/color :purple))
    :border-radius "0 0 1em 1em"
    :text-align :center
    :left (px 0)}])
