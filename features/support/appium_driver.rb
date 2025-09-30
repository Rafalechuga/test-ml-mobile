require 'appium_lib'

class AppiumDriver
  class << self
    def driver
      @driver ||= create_driver
    end

    private

    def create_driver
      options = {
        caps: {
          platformName: 'Android',
          'appium:platformVersion': '13',
          'appium:deviceName': 'emulator-5554',
          'appium:automationName': 'UiAutomator2',
          'appium:app': '/workspace/mercadolibre.apk',
          'appium:appPackage': 'com.mercadolibre',
          'appium:appActivity': '.home.ui.splash.SplashActivity',
          'appium:noReset': false,
          'appium:autoGrantPermissions': true,
          'appium:newCommandTimeout': 3600
        },
        appium_lib: {
          wait: 30,
          wait_timeout: 30,
          wait_interval: 1
        }
      }

      Appium::Driver.new(options, true).start_driver
      Appium.promote_appium_methods Object
      
      @driver
    end
  end
end