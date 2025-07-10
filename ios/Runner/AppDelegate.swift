import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey(AIzaSyDL0aILsDTjN4HQVBXDZC5NGo_AwkWq3Rg)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
