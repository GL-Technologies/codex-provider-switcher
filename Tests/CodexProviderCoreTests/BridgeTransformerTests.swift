import XCTest
@testable import CodexProviderCore

final class BridgeTransformerTests: XCTestCase {
    func testCollapsesDeveloperInstructionsAndCustomTool() throws {
        let profile = ProviderProfile(name: "Test", model: "model", baseURL: "https://example.com/v1")
        let request: [String: Any] = [
            "model": "model",
            "instructions": "base instruction",
            "input": [
                ["type": "message", "role": "developer", "content": [["type": "input_text", "text": "developer rule"]]],
                ["type": "message", "role": "user", "content": [["type": "input_text", "text": "hello"]]]
            ],
            "tools": [[
                "type": "custom",
                "name": "apply_patch",
                "format": ["type": "grammar", "syntax": "lark"]
            ]]
        ]

        let conversion = BridgeTransformer.makeChatRequest(from: request, profile: profile)
        let messages = try XCTUnwrap(conversion.body["messages"] as? [[String: Any]])
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0]["role"] as? String, "system")
        XCTAssertTrue((messages[0]["content"] as? String)?.contains("base instruction") == true)
        XCTAssertTrue((messages[0]["content"] as? String)?.contains("developer rule") == true)

        let tools = try XCTUnwrap(conversion.body["tools"] as? [[String: Any]])
        let function = try XCTUnwrap(tools.first?["function"] as? [String: Any])
        XCTAssertEqual(function["name"] as? String, "apply_patch")
    }

    func testRestoresCustomToolCallFromChatResponse() throws {
        let profile = ProviderProfile(name: "Test", model: "model", baseURL: "https://example.com/v1")
        let request: [String: Any] = [
            "model": "model",
            "input": "edit it",
            "tools": [["type": "custom", "name": "apply_patch"]]
        ]
        let conversion = BridgeTransformer.makeChatRequest(from: request, profile: profile)
        let chat: [String: Any] = [
            "id": "chatcmpl-test",
            "model": "model",
            "choices": [[
                "finish_reason": "tool_calls",
                "message": [
                    "role": "assistant",
                    "content": NSNull(),
                    "tool_calls": [[
                        "id": "call_1",
                        "type": "function",
                        "function": ["name": "apply_patch", "arguments": "{\"input\":\"*** Begin Patch\"}"]
                    ]]
                ]
            ]]
        ]

        let response = try BridgeTransformer.makeResponsesObject(from: chat, model: "model", toolContext: conversion.toolContext)
        let output = try XCTUnwrap(response["output"] as? [[String: Any]])
        XCTAssertEqual(output.first?["type"] as? String, "custom_tool_call")
        XCTAssertEqual(output.first?["name"] as? String, "apply_patch")
        XCTAssertEqual(output.first?["input"] as? String, "*** Begin Patch")
    }

    func testNamespaceToolNamesAreFlattenedAndRestored() throws {
        let profile = ProviderProfile(name: "Test", model: "model", baseURL: "https://example.com/v1")
        let request: [String: Any] = [
            "model": "model",
            "input": "use tool",
            "tools": [[
                "type": "namespace",
                "name": "workspace",
                "tools": [["type": "function", "name": "read_file", "parameters": ["type": "object"]]]
            ]]
        ]
        let conversion = BridgeTransformer.makeChatRequest(from: request, profile: profile)
        let tools = try XCTUnwrap(conversion.body["tools"] as? [[String: Any]])
        let function = try XCTUnwrap(tools.first?["function"] as? [String: Any])
        XCTAssertEqual(function["name"] as? String, "workspace__read_file")

        let chat: [String: Any] = [
            "choices": [[
                "message": [
                    "tool_calls": [[
                        "id": "call_2",
                        "function": ["name": "workspace__read_file", "arguments": "{}"]
                    ]]
                ]
            ]]
        ]
        let response = try BridgeTransformer.makeResponsesObject(from: chat, model: "model", toolContext: conversion.toolContext)
        let output = try XCTUnwrap(response["output"] as? [[String: Any]])
        XCTAssertEqual(output.first?["type"] as? String, "function_call")
        XCTAssertEqual(output.first?["name"] as? String, "read_file")
        XCTAssertEqual(output.first?["namespace"] as? String, "workspace")
    }
}
