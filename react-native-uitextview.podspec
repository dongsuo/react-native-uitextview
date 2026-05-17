require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

# Detect whether the new architecture / Fabric is enabled
new_arch_enabled = ENV['RCT_NEW_ARCH_ENABLED'] == '1'


Pod::Spec.new do |s|
  s.name         = "react-native-uitextview"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  # Require iOS 16+. TextKit 2 (NSTextLayoutManager) is a hard dependency for
  # the fast long-text / CJK rendering path used in this component.
  s.platforms    = { :ios => "16.0" }
  s.source       = { :git => "https://github.com/bluesky-social/react-native-uitextview.git", :tag => "#{s.version}" }

  # Include module‑authored Obj‑C/Obj‑C++ plus the C++ files that Codegen
  # writes to build/generated/ios during `pod install`
  s.source_files = [
    "ios/**/*.{h,mm,cpp}",
  ]

  install_modules_dependencies(s)

  # ---------- Fabric Components (when using frameworks) ----------
  if ENV['USE_FRAMEWORKS'] != nil && new_arch_enabled
    add_dependency(s, "React-FabricComponents", :additional_framework_paths => [
      "react/renderer/textlayoutmanager/platform/ios",
    ])
  end
end
