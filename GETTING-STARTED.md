# Getting Started with Twyns

This guide will help you set up the Twyns project, including the Flutter application and the local model server.

## Prerequisites

- **Flutter SDK:** Version 3.0 or higher.
- **Dart SDK:** Version 3.0 or higher.
- **Python:** Version 3.8 or higher (for the model server).
- **Xcode:** Version 15.0 or higher (for iOS development).
- **CocoaPods:** Required for iOS dependency management.
- **Git LFS:** Required for downloading large model files.

## 1. Model Setup

You need to acquire the ExecuTorch-compatible model (`.pte`) and tokenizer files.

### Option A: Download from Hugging Face (Recommended)

The ExecuTorch community provides pre-converted models.

1.  Visit the [ExecuTorch Community on Hugging Face](https://huggingface.co/executorch-community).
2.  Select a model (e.g., `Llama-3.2-1B-Instruct`).
3.  Download the following files:
    -   `model.pte` (Look for files ending in `.pte`, e.g., `xnnpack_llama3_2_1b_instruct.pte`)
    -   `tokenizer.model` (or `tokenizer.bin`)

### Option B: Manually Convert Models

If you prefer to convert models yourself, follow the official [ExecuTorch Documentation](https://pytorch.org/executorch/stable/llm/llm-getting-started.html).

## 2. Server Setup

The Python server hosts the model files for the Flutter app to download on demand.

1.  **Navigate to the server directory:**
    ```bash
    cd server
    ```

2.  **Create a virtual environment (optional but recommended):**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```

3.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Place Model Files:**
    Copy your downloaded `.pte` and `tokenizer.model` files into the `server/models/` directory.
    
    *Note: Ensure the filenames match what the server expects or update `main.py` if necessary.*

5.  **Start the Server:**
    Open a **new terminal window** and run:
    ```bash
    python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
    ```
    
    *Keep this terminal open.*

## 3. Flutter App Setup

1.  **Navigate to the project root:**
    ```bash
    cd twyns
    ```

2.  **Install Flutter dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Install iOS dependencies:**
    ```bash
    cd ios
    pod install
    cd ..
    ```

    > **Important:** If you encounter issues with `executorch_bridge_flutter`, refer to its `README.md` for specific Xcode configuration steps (e.g., adding `-all_load` to linker flags).

4.  **Run the Application:**
    Ensure your iOS simulator or physical device is connected.
    ```bash
    flutter run
    ```

## 4. Usage

1.  Launch the app on your device.
2.  The app should automatically attempt to connect to your local server (ensure your device and computer are on the same network if using a physical device, or use `localhost` for simulator).
3.  Download the model files through the app interface.
4.  Start chatting with your Digital Twin!

## Troubleshooting

-   **Server Connection:** If the app cannot connect to the server, check your network settings and ensure the server is running on port 8000.
-   **Model Loading:** If the model fails to load, verify that the `.pte` file is compatible with the current version of ExecuTorch used in the plugin.
-   **Linker Errors:** If the iOS build fails, double-check the `Other Linker Flags` in Xcode as described in the `executorch_bridge_flutter` documentation.
