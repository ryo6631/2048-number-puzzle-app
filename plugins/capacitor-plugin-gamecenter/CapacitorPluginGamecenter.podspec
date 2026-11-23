Pod::Spec.new do |s|
  s.name = 'CapacitorPluginGamecenter'
  s.version = '1.0.0'
  s.summary = 'Minimal Game Center bridge for Capacitor'
  s.license = 'MIT'
  s.homepage = 'https://example.com'
  s.author = 'Yukiya'
  s.source = { :path => '.' }
  s.source_files = 'ios/Sources/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.1'
  s.dependency 'Capacitor'
end
