//
//  BannerAdCoordinator.swift
//  SYKeyboard
//
//  Created by 서동환 on 12/2/25.
//

import SwiftUI
import OSLog

import FirebaseAnalytics
import GoogleMobileAds

final class BannerAdCoordinator: NSObject {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
    private let parent: BannerAdView
    
    // MARK: - Initializer
    
    init(parent: BannerAdView) {
        self.parent = parent
    }
    
    // MARK: - Internal Methods
    
    func handlePaidEvent(value: AdValue, banner: BannerView) {
        let currencyCode = value.currencyCode
        let amount = value.value
        
        logger.debug("PAID EVENT: \(amount) \(currencyCode)")
        
        Analytics.logEvent(AnalyticsEventAdImpression, parameters: [
            AnalyticsParameterAdPlatform: "google_mobile_ads",
            AnalyticsParameterAdSource: banner.responseInfo?.loadedAdNetworkResponseInfo?.adNetworkClassName ?? "unknown",
            AnalyticsParameterAdFormat: "banner",
            AnalyticsParameterAdUnitName: banner.adUnitID ?? "unknown",
            AnalyticsParameterCurrency: currencyCode,
            AnalyticsParameterValue: amount
        ])
    }
}

// MARK: - BannerViewDelegate

extension BannerAdCoordinator: BannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        parent.isAdReceived = true
        
        let responseInfo = bannerView.responseInfo
        logger.debug("DID RECEIVE AD:\n\(responseInfo)")
        
        let adNetworkClassName = responseInfo?.loadedAdNetworkResponseInfo?.adNetworkClassName
        let latency = responseInfo?.loadedAdNetworkResponseInfo?.latency
        Analytics.logEvent("receive_ad_success", parameters: [
            AnalyticsParameterAdFormat: "banner",
            AnalyticsParameterAdSource: adNetworkClassName ?? "unknown",
            "latency": latency ?? 0
        ])
    }
    
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        parent.isAdReceived = false
        let responseInfo = bannerView.responseInfo
        logger.error("FAILED TO RECEIVE AD: \(error.localizedDescription)\n\(responseInfo)")
        
        Analytics.logEvent("receive_ad_failed", parameters: [
            AnalyticsParameterAdFormat: "banner",
            "error_message": error.localizedDescription
        ])
    }
    
    func bannerViewDidRecordClick(_ bannerView: BannerView) {
        logger.debug("BANNER AD CLICKED")
        
        Analytics.logEvent("ad_click", parameters: [
            AnalyticsParameterAdFormat: "banner",
            AnalyticsParameterAdUnitName: bannerView.adUnitID ?? "unknown"
        ])
    }
    
    func bannerViewWillPresentScreen(_ bannerView: BannerView) {
        Analytics.logEvent("ad_open_screen", parameters: nil)
    }
    
    func bannerViewDidDismissScreen(_ bannerView: BannerView) {
        Analytics.logEvent("ad_close_screen", parameters: nil)
    }
}
