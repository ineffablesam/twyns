# Twyns: The On-Device AI Digital Twin
### *ARM Hackathon Submission*

## 🚀 Project Overview
**Twyns** is a next-generation "Digital Twin" application that brings personalized, privacy-first AI directly to the user's pocket. By leveraging **ExecuTorch** and the power of **ARM-based mobile processors**, Twyns runs advanced Large Language Models (LLMs) like Llama locally on the device. This eliminates the need for cloud latency, ensures absolute data privacy, and demonstrates the raw compute capability of modern mobile hardware.

## 💡 The Problem
Cloud-based AI assistants suffer from three critical issues:
1.  **Latency:** Network round-trips break the illusion of a natural, real-time conversation.
2.  **Privacy:** Personal data is sent to remote servers, raising security concerns.
3.  **Connectivity:** They fail without an internet connection.

## 🛠 The Solution: Edge AI on ARM
Twyns solves these problems by moving the "brain" to the edge.
- **Local Inference:** We utilize `executorch_bridge_flutter` to run optimized `.pte` (PyTorch ExecuTorch) models directly on the device's CPU/NPU.
- **Zero Latency:** By processing tokens locally, we achieve instant response times essential for fluid voice conversations.
- **Offline Capability:** Your Digital Twin lives on your phone, not in a data center.

## 🔧 Technical Innovation & ARM Optimization

### 1. High-Performance Local Inference (ExecuTorch)
At the heart of Twyns is the integration of **ExecuTorch**, PyTorch's optimized runtime for edge devices.
- We run quantized **Llama models** optimized for ARM architectures.
- The inference engine takes advantage of ARM's efficient instruction sets to deliver acceptable tokens-per-second (TPS) on mobile devices without draining the battery.

### 2. Real-Time Voice Pipeline
Twyns isn't just a text bot; it's a voice-first experience.
- **Input:** Streaming speech recognition (`mic_stream_recorder`) feeds directly into the local model.
- **Output:** The AI's text response is generated and visualized in real-time.
- **Efficiency:** The entire pipeline—from voice capture to model inference to UI rendering—is optimized to run smoothly on mobile SoCs.

### 3. Visual Immersion with Shaders
To make the AI feel "alive" without heavy GPU overhead:
- We use **GLSL Shaders** (`flutter_shaders`) for the "Pulse" visualization.
- These shaders run efficiently on the mobile GPU, providing a high-fidelity visual representation of the AI's "thought process" and voice activity with minimal impact on the main thread.

## 🏗 Tech Stack
- **Core Platform:** Flutter (Dart) - *Cross-platform, compiled to native ARM machine code.*
- **AI Runtime:** ExecuTorch (PyTorch) - *Optimized for Edge/ARM.*
- **Model:** Llama (Quantized for Mobile).
- **Backend Services:** Supabase (Auth/Sync) & Python FastAPI (Model Delivery).
- **State Management:** GetX.

## 🎯 Why This Matters for ARM
Twyns demonstrates that **ARM-powered mobile devices are now capable of hosting complex, generative AI workloads** that were previously restricted to data centers. By optimizing the entire stack—from the model (ExecuTorch) to the UI (Flutter)—we unlock a new class of privacy-preserving, high-performance applications tailored for the edge.
