//
//  PredictiveTextSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 3/12/26.
//

import SwiftUI

import SYKeyboardCore

import FirebaseAnalytics

struct PredictiveTextSettingsView: View {
    
    // MARK: - Properties
    
    @AppStorage(UserDefaultsKeys.isTextReplacementEnabled, store: UserDefaultsManager.shared.storage)
    private var isTextReplacementEnabled = DefaultValues.isTextReplacementEnabled
    
    @AppStorage(UserDefaultsKeys.isPredictiveTextEnabled, store: UserDefaultsManager.shared.storage)
    private var isPredictiveTextEnabled = DefaultValues.isPredictiveTextEnabled
    
    @State private var showResetLearnedWordsAlert = false
    @State private var showResetNGramAlert = false
    @State private var showResetAllAlert = false
    
    // MARK: - Content
    
    var body: some View {
        Toggle(isOn: $isTextReplacementEnabled, label: {
            Text("텍스트 대치")
            Text("시스템 설정의 텍스트 대치 단축키 사용")
                .font(.caption)
        })
        .onChange(of: isTextReplacementEnabled) { newValue in
            Analytics.setUserProperty(newValue.analyticsValue,
                                      forName: "pref_text_replacement")
            Analytics.logEvent("text_replacement", parameters: [
                "view": "InputSettingsView",
                "enabled": newValue.analyticsValue
            ])
            hideKeyboard()
        }
        
        Toggle(isOn: $isPredictiveTextEnabled, label: {
            Text("자동완성 텍스트")
            Text("키보드 상단에 자동완성 텍스트 표시")
                .font(.caption)
        })
        .onChange(of: isPredictiveTextEnabled) { newValue in
            Analytics.setUserProperty(newValue.analyticsValue,
                                      forName: "pref_predictive_text")
            Analytics.logEvent("predictive_text", parameters: [
                "view": "InputSettingsView",
                "enabled": newValue.analyticsValue
            ])
            hideKeyboard()
        }
        
        Button(role: .destructive) {
            showResetAllAlert = true
        } label: {
            Text("학습 데이터 초기화")
        }
        .alert("학습 데이터 초기화", isPresented: $showResetAllAlert) {
            Button("취소", role: .cancel) {}
            Button("확인", role: .destructive) {
                resetLearnedWords()
                resetNGramData()
            }
        } message: {
            Text("학습한 단어와 예측 데이터가 모두 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
        }
    }
}

// MARK: - Private Methods

private extension PredictiveTextSettingsView {
    func resetLearnedWords() {
        let engine = TextCheckerPredictiveTextEngine(languages: ["ko_KR", "en-US"])
        engine.unlearnAllWords()
        
        Analytics.logEvent("reset_learned_words", parameters: [
            "view": "PredictiveTextSettingsView"
        ])
    }
    
    func resetNGramData() {
        let engine = NGramPredictiveTextEngine()
        engine.resetAllData()
        
        Analytics.logEvent("reset_ngram_data", parameters: [
            "view": "PredictiveTextSettingsView"
        ])
    }
}

// MARK: - Preview

#Preview {
    PredictiveTextSettingsView()
}
