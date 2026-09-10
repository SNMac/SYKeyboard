//
//  ClipboardImagePolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/10/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("클립보드 이미지 저장 정책 검증")
struct ClipboardImagePolicyTests {

    @Test("타입 우선순위는 JPEG, HEIC, PNG 순이고 TIFF·GIF만 있으면 nil")
    func test타입우선순위() {
        #expect(ClipboardImagePolicy.storableType(in: ["public.png", "public.jpeg"]) == "public.jpeg")
        #expect(ClipboardImagePolicy.storableType(in: ["public.png", "public.heic"]) == "public.heic")
        #expect(ClipboardImagePolicy.storableType(in: ["public.tiff", "public.png"]) == "public.png")
        #expect(ClipboardImagePolicy.storableType(in: ["public.tiff", "com.compuserve.gif"]) == nil)
        #expect(ClipboardImagePolicy.storableType(in: []) == nil)
    }

    @Test("바이트 한도는 12 MB까지, 픽셀 한도는 24,000,000까지 저장 가능")
    func test바이트픽셀한도_경계값() {
        let bytes = ClipboardImagePolicy.maxByteSize
        #expect(bytes == 12 * 1_024 * 1_024)
        #expect(ClipboardImagePolicy.isStorable(byteSize: bytes, pixelWidth: 4_000, pixelHeight: 6_000))
        #expect(ClipboardImagePolicy.isStorable(byteSize: bytes + 1, pixelWidth: 100, pixelHeight: 100) == false)
        #expect(ClipboardImagePolicy.isStorable(byteSize: 1, pixelWidth: 4_000, pixelHeight: 6_001) == false)
        #expect(ClipboardImagePolicy.isStorable(byteSize: 0, pixelWidth: 1, pixelHeight: 1) == false)
        #expect(ClipboardImagePolicy.isStorable(byteSize: 1, pixelWidth: 0, pixelHeight: 1) == false)
    }

    @Test("남은 메모리가 한도의 2배 + 8 MB 이상일 때만 캡처")
    func test메모리여유판정() {
        let required = ClipboardImagePolicy.maxByteSize * 2 + 8 * 1_024 * 1_024
        #expect(ClipboardImagePolicy.requiredAvailableMemory == required)
        #expect(ClipboardImagePolicy.hasEnoughMemory(available: required))
        #expect(ClipboardImagePolicy.hasEnoughMemory(available: required - 1) == false)
    }

    @Test("원본 파일 확장자는 타입에서 유도")
    func test확장자유도() {
        #expect(ClipboardImagePolicy.fileExtension(for: "public.jpeg") == "jpg")
        #expect(ClipboardImagePolicy.fileExtension(for: "public.heic") == "heic")
        #expect(ClipboardImagePolicy.fileExtension(for: "public.png") == "png")
        #expect(ClipboardImagePolicy.fileExtension(for: "public.tiff") == "img")
    }

    @Test("썸네일·미리보기 픽셀 크기는 키보드 메모리에 맞게 작다")
    func test썸네일미리보기크기() {
        #expect(ClipboardImagePolicy.thumbnailMaxPixelSize == 240)
        #expect(ClipboardImagePolicy.keyboardPreviewMaxPixelSize == 600)
        #expect(ClipboardImagePolicy.appPreviewMaxPixelSize == 1_200)
    }
}
