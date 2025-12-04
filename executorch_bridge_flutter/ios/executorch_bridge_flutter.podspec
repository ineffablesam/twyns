Pod::Spec.new do |s|
  s.name             = 'executorch_bridge_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Flutter bridge for ExecuTorch on-device AI runtime.'
  s.description      = <<-DESC
Flutter bridge for ExecuTorch on-device AI runtime.
Requires manual Swift Package Manager setup.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'executorch_bridge_flutter/Sources/executorch_bridge_flutter/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '17.0'

  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
  
  s.prepare_command = <<-CMD
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ⚠️  IMPORTANT: ExecuTorch Setup Required                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "ExecuTorch uses Swift Package Manager (SPM)."
    echo "After 'pod install', you must:"
    echo ""
    echo "1. Open: ios/Runner.xcworkspace"
    echo "2. Add Package: https://github.com/pytorch/executorch"
    echo "3. Branch: swiftpm-1.0.1"
    echo "4. Add these 9 libraries to Runner target:"
    echo "   - executorch_llm_debug"
    echo "   - kernels_quantized"
    echo "   - kernels_optimized"
    echo "   - executorch_debug"
    echo "   - backend_xnnpack"
    echo "   - kernels_torchao"
    echo "   - backend_mps"
    echo "   - kernels_llm"
    echo "   - backend_coreml"
    echo ""
    echo "5. ⚠️  CRITICAL: Add linker flag in Build Settings:"
    echo "   Build Settings → Other Linker Flags → Add '-all_load'"
    echo "   (Required for both Debug and Release)"
    echo ""
    echo "Without -all_load, tokenizers will fail at runtime!"
    echo ""
    echo "See plugin README for detailed step-by-step instructions."
    echo ""
  CMD
end