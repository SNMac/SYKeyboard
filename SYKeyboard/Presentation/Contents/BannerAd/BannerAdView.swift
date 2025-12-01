//
//  BannerAdView.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/17/25.
//

import SwiftUI
import OSLog

import FirebaseAnalytics
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    
    // MARK: - Properties
    
    let adSize: AdSize
    @Binding var isAdReceived: Bool
    
    // MARK: - Internal Methods
    
    func makeUIView(context: Context) -> UIView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = Configuration.admobID
        banner.load(Request())
        banner.delegate = context.coordinator
        
        let coordinator = context.coordinator
        banner.paidEventHandler = { [weak coordinator, weak banner] value in
            guard let banner else { return }
            coordinator?.handlePaidEvent(value: value, banner: banner)
        }
        
        return banner
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> BannerAdCoordinator {
        return BannerAdCoordinator(parent: self)
    }
}

// MARK: - AdMob ID Configuration

private extension BannerAdView {
    enum Configuration: String  {
        case debug
        case release
        
        static var current: Configuration? {
            guard let buildConfigString = Bundle.main.infoDictionary?["Configuration"] as? String else { return nil }
            return Configuration(rawValue: buildConfigString.lowercased())
        }
        
        static var admobID: String {
            switch current {
            case .release:
                return "ca-app-pub-9204044817130515/6474193447"  // 실제 광고 단위 ID
            default:
                return "ca-app-pub-3940256099942544/2435281174"  // 테스트 전용 광고 단위 ID
            }
        }
    }
}
