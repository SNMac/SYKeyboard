//
//  BannerAdView.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/17/25.
//

import SwiftUI
import GoogleMobileAds
import FirebaseAnalytics
import OSLog

struct BannerAdView: UIViewRepresentable {
    
    // MARK: - Properties
    
    @Binding var isAdReceived: Bool
    let adSize: AdSize
    
    // MARK: - Initializer
    
    init(_ adSize: AdSize, isAdReceived: Binding<Bool>) {
        self.adSize = adSize
        self._isAdReceived = isAdReceived
    }
    
    // MARK: - Internal Methods
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        view.addSubview(context.coordinator.bannerView)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.bannerView.adSize = adSize
    }
    
    func makeCoordinator() -> BannerAdCoordinator {
        return BannerAdCoordinator(self)
    }
}

final class BannerAdCoordinator: NSObject, BannerViewDelegate {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
    private(set) lazy var bannerView: BannerView = {
        let banner = BannerView(adSize: parent.adSize)
        banner.adUnitID = Configuration.admobID
        banner.load(Request())
        banner.delegate = self
        
        return banner
    }()
    
    private let parent: BannerAdView
    
    // MARK: - Initializer
    
    init(_ parent: BannerAdView) {
        self.parent = parent
    }
}

// MARK: - BannerViewDelegate Methods

extension BannerAdCoordinator {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        parent.isAdReceived = true
        
        let responseInfo = bannerView.responseInfo
        logger.debug("DID RECEIVE AD:\n\(responseInfo)")
        
        let adNetworkClassName = responseInfo?.loadedAdNetworkResponseInfo?.adNetworkClassName
        let latency = responseInfo?.loadedAdNetworkResponseInfo?.latency
        Analytics.logEvent("receive_ad_success", parameters: [
            "adNetworkClassName": "\(String(describing: adNetworkClassName))",
            "latency": "\(String(describing: latency))"
        ])
    }
    
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        parent.isAdReceived = false
        
        let responseInfo = bannerView.responseInfo
        logger.error("FAILED TO RECEIVE AD: \(error.localizedDescription)\n\(responseInfo)")
        
        Analytics.logEvent("receive_ad_failed", parameters: [
            "error": "\(error.localizedDescription)"
        ])
    }
}

// MARK: - AdMob ID Configuration

private extension BannerAdCoordinator {
    enum Configuration: String  {
        case debug
        case release
        
        static var current: Configuration? {
            guard let buildConfigString = Bundle.main.infoDictionary?["Configuration"] as? String else { return nil }
            return Configuration(rawValue: buildConfigString.lowercased())
        }
        
        static var admobID: String {
            switch current {
            case .debug:
                return "ca-app-pub-3940256099942544/2435281174"  // 테스트 전용 광고 단위 ID
            case .release:
                return "ca-app-pub-9204044817130515/6474193447"  // 실제 광고 단위 ID
            default:
                return ""
            }
        }
    }
}
