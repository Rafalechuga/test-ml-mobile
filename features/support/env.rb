require 'appium_lib'
require 'cucumber'
require 'rspec'

APP_PATH = ENV['APP_PATH'] || '/workspace/mercadolibre.apk'

def load_appium_config
  Appium.load_appium_txt file: File.expand_path('../appium.txt', __FILE__), verbose: true
end

def caps
  {
    platformName: 'Android',
    platformVersion: '13',
    deviceName: 'emulator-5554',
    automationName: 'UiAutomator2',
    app: APP_PATH,
    appPackage: 'com.mercadolibre',
    appActivity: '.home.ui.splash.SplashActivity',
    noReset: false,
    autoGrantPermissions: true,
    newCommandTimeout: 3600,
    adbExecTimeout: 60000
  }
end

Appium::Driver.new({ caps: caps, appium_lib: { wait: 30 } }, true)
Appium.promote_appium_methods Object

Before do
  $driver.start_driver
end

After do |scenario|
  if scenario.failed?
    # Take screenshot on failure
    time_stamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    screenshot_name = "screenshot_#{time_stamp}.png"
    screenshot_file = File.join(Dir.pwd, screenshot_name)
    $driver.screenshot(screenshot_file)
    embed(screenshot_file, 'image/png')
  end
  
  $driver.driver_quit
end