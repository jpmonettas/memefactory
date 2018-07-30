(ns memefactory.styles.pages.mymemefolio
  (:require [garden.def :refer [defstyles]]
            [garden.stylesheet :refer [at-media]]
            [clojure.string :as s]
            [memefactory.styles.base.icons :refer [icons]]
            [memefactory.styles.base.borders :refer [border-top border-bottom]]
            [memefactory.styles.base.colors :refer [color]]
            [memefactory.styles.base.fonts :refer [font]]
            [memefactory.styles.base.media :refer [for-media-min for-media-max]]
            [memefactory.styles.component.search :refer [search-panel]]
            [garden.selectors :as sel]
            [garden.units :refer [pt px em rem]]
            [clojure.string :as str]))

(defstyles core
  [:.memefolio-page
   (search-panel {:background-panel-image "/assets/icons/search-background.png"
                  :color :mymemefolio-green
                  :icon "/assets/icons/mymemefolio-green.png"})

   [:.tiles
    {:display :block
     :margin-top (em 2)
     :padding-top (em 2)
     :padding-bottom (em 2)
     :margin-right (em 6)
     :margin-left (em 6)
     :background-color (color :meme-panel-bg)
     :border-radius "1em 1em 1em 1em"}
    [">div>div"
     {:display :flex
      :flex-wrap :wrap
      :justify-content :space-evenly}]]
   [:.tabs
    {:display :flex
     :height (em 3)
     :line-height (em 3)
     :flex-wrap :wrap
     :justify-content :space-evenly}
    [">div"
     [:a
      {:color (color :section-subcaption)}
      [:&.active
       (border-bottom {:color (color :pink)
                       :width (px 2)})]]]]])
