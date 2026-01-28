//
//  BannerAdCoordinator.swift
//  SYKeyboard
//
//  Created by 서동환 on 12/2/25.
//

import SwiftUI
import OSLog

import GoogleMobileAds

final class BannerAdCoordinator: NSObject {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )
    
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
    }
}

// MARK: - BannerViewDelegate

extension BannerAdCoordinator: BannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        parent.isAdReceived = true
        
        let responseInfo = bannerView.responseInfo
        logger.debug("DID RECEIVE AD:\n\(responseInfo)")
    }
    
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        parent.isAdReceived = false
        let responseInfo = bannerView.responseInfo
        logger.error("FAILED TO RECEIVE AD: \(error.localizedDescription)\n\(responseInfo)")
    }
    
    func bannerViewDidRecordClick(_ bannerView: BannerView) {
        logger.debug("BANNER AD CLICKED")
    }
    
    func bannerViewWillPresentScreen(_ bannerView: BannerView) {
        logger.debug("BANNER AD PRESENT SCREEN")
    }
    
    func bannerViewDidDismissScreen(_ bannerView: BannerView) {
        logger.debug("BANNER AD DISMISS SCREEN")
    }
}
