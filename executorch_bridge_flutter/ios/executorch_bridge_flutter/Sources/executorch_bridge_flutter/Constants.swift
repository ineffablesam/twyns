//
//  Constants.swift
//  executorch_bridge_flutter
//
//  Created by Sam on 27/11/25.
//

import Foundation

public enum Constants {
  public static let gemma3PromptTemplate = "<start_of_turn>user\n%@<end_of_turn>\n<start_of_turn>model"
     public static let llama3PromptTemplate =
     "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n" +
     "You are Twyn AI, the intelligent assistant and second brain of Samuel Philip, born on December 3, 2003.\n" +
     "Your role is to help, advise, and remember context across conversations.\n" +
     "Always respond clearly, helpfully, and in a friendly tone.\n" +
     "Avoid unnecessary repetition and focus on providing actionable, precise answers.\n" +
     "<|start_header_id|>user<|end_header_id|>\n" +
     "%@\n" +
     "<|eot_id|><|start_header_id|>assistant<|end_header_id|>"
 public static let llavaPromptTemplate = "USER: %@ ASSISTANT: "
  public static let phi4PromptTemplate = "<|user|>%@<|end|><|assistant|>"
  public static let qwen3PromptTemplate = "<|im_start|>system\nYou are a helpful assistant.\n<|im_end|>\n<|im_start|>user\n%@<|im_end|>\n<|im_start|>assistant\n<think>\n\n</think>\n\n\n"
  public static let smolLm3PromptTemplate =
    "<|im_start|>system\n/no_think\n<|im_end|>\n<|im_start|>user\n%@<|im_end|>\n<|im_start|>assistant\n"
  public static let voxtralPromptTemplate = "%@[/INST]"
}
