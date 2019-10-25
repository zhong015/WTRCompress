Pod::Spec.new do |s|

  s.name         = "WTRCompress"
  s.version      = "0.0.1"
  s.summary      = "压缩解压集合"

  s.homepage     = "https://github.com/zhong015/WTRCompress.git"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }

  s.author             = { "wtr0@qq.com" => "wtr0@qq.com" }
  s.source           = { :git => 'https://github.com/zhong015/WTRCompress.git', :tag => s.version.to_s }

  s.ios.deployment_target = "9.0"

  s.public_header_files = 'src/*.h'
  s.source_files  = "src/**/*.{h,m,c}"

  s.dependency 'UnrarKit' , '2.9'
  s.dependency 'LzmaSDK-ObjC'

  s.requires_arc = true

  s.pod_target_xcconfig = {"OTHER_CFLAGS" => "$(inherited) -Wno-strict-prototypes"}

end
