Pod::Spec.new do |s|
  s.name         = "RBEQueuePool"
  s.version      = "1.0.0"
  s.summary      = "RBEQueuePool is a library that helps you managing your multithreads"
  s.description  = <<-DESC
                    RBEQueuePool is a library that helps you managing your multithreads.
                   DESC
  s.author       = "Robbie"
  s.license      = "MIT"
  s.homepage     = "https://github.com/robbie23/RBEQueuePool" 
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/robbie23/RBEQueuePool.git", 
                     :tag => s.version }

  s.source_files  = "RBEQueuePool/*.{h,m}"
  s.public_header_files = 'RBEQueuePool/RBEQueuePool.h'

end