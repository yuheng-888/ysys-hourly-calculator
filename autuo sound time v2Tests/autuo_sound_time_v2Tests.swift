//
//  autuo_sound_time_v2Tests.swift
//  autuo sound time v2Tests
//
//  Created by 陆玉缘 on 2025/7/5.
//

import Testing
@testable import autuo_sound_time_v2

struct autuo_sound_time_v2Tests {

    @Test func projectNameFieldUsesRememberedValueWhenCurrentInputIsBlank() async throws {
        let resolved = ProjectNameMemory.prefilledProjectName(currentInput: "   ", rememberedProjectName: "有声书A")

        #expect(resolved == "有声书A")
    }

    @Test func projectNameFieldPreservesCurrentInputWhenItExists() async throws {
        let resolved = ProjectNameMemory.prefilledProjectName(currentInput: "新项目", rememberedProjectName: "旧项目")

        #expect(resolved == "新项目")
    }

    @Test func rememberProjectNameTrimsWhitespaceAndRejectsBlankValues() async throws {
        let remembered = ProjectNameMemory.rememberedProjectName(from: "  新项目  ")
        let ignored = ProjectNameMemory.rememberedProjectName(from: "   ")

        #expect(remembered == "新项目")
        #expect(ignored == nil)
    }

}
