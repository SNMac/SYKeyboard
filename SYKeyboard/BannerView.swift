//
//  BannerView.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/17/25.
//

import SwiftUI
import GoogleMobileAds
import OSLog

// [START create_banner_view]
struct BannerView: UIViewRepresentable {
    let adSize: GADAdSize
    
    init(_ adSize: GADAdSize) {
        self.adSize = adSize
    }
    
    func makeUIView(context: Context) -> UIView {
        // Wrap the GADBannerView in a UIView. GADBannerView automatically reloads a new ad when its
        // frame size changes; wrapping in a UIView container insulates the GADBannerView from size
        // changes that impact the view returned from makeUIView.
        let view = UIView()
        view.addSubview(context.coordinator.bannerView)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.bannerView.adSize = adSize
    }
    
    func makeCoordinator() -> BannerCoordinator {
        return BannerCoordinator(self)
    }
    // [END create_banner_view]
    

    // MARK: - ‼️ 광고 단위 ID 주의 ‼️ (banner.adUnitID)
    // [START create_banner]
    class BannerCoordinator: NSObject, GADBannerViewDelegate {
        private let log = OSLog(subsystem: "github.com-SNMac.SYKeyboard", category: "BannerCoordinator")
        
        private(set) lazy var bannerView: GADBannerView = {
            let banner = GADBannerView(adSize: parent.adSize)
            // [START load_ad]
            
            banner.adUnitID = "ca-app-pub-9204044817130515/6474193447"  // 실제 광고 단위 ID
//            banner.adUnitID = "ca-app-pub-3940256099942544/2435281174"  // 테스트 전용 광고 단위 ID
            
            banner.load(GADRequest())
            // [END load_ad]
            // [START set_delegate]
            banner.delegate = self
            // [END set_delegate]
            return banner
        }()
        
        let parent: BannerView
        
        init(_ parent: BannerView) {
            self.parent = parent
        }
        // [END create_banner]
        
        // MARK: - GADBannerViewDelegate methods
        
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            os_log("DID RECEIVE AD.", log: log, type: .debug)
        }
        
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            os_log("FAILED TO RECEIVE AD: %@", log: log, type: .debug, error.localizedDescription)
        }
    }
}
