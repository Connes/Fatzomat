import Flutter
import UIKit
import CoreLocation

class SceneDelegate: FlutterSceneDelegate, CLLocationManagerDelegate {
  private let locationChannelName = "schmackofatz/location"
  private var locationManager: CLLocationManager?
  private var pendingLocationResult: FlutterResult?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    let channel = FlutterMethodChannel(name: locationChannelName, binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "getCurrentLocation": self.getCurrentLocation(result)
      default: result(FlutterMethodNotImplemented)
      }
    }
  }

  private func getCurrentLocation(_ result: @escaping FlutterResult) {
    if !CLLocationManager.locationServicesEnabled() {
      result(FlutterError(code: "LOCATION_DISABLED", message: "Die Standortdienste sind deaktiviert. Bitte aktiviere den Standort und versuche es erneut.", details: nil))
      return
    }
    if pendingLocationResult != nil {
      result(FlutterError(code: "LOCATION_BUSY", message: "Eine Standortanfrage läuft bereits.", details: nil))
      return
    }

    let manager = CLLocationManager()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager = manager
    pendingLocationResult = result

    switch manager.authorizationStatus {
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    case .authorizedWhenInUse, .authorizedAlways:
      manager.requestLocation()
    case .denied, .restricted:
      pendingLocationResult = nil
      result(FlutterError(code: "LOCATION_PERMISSION", message: "Die Standortberechtigung wurde abgelehnt. Bitte erlaube den Standort in den App-Einstellungen.", details: nil))
    @unknown default:
      pendingLocationResult = nil
      result(FlutterError(code: "LOCATION_PERMISSION", message: "Die Standortberechtigung konnte nicht bestimmt werden.", details: nil))
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      manager.requestLocation()
    case .denied, .restricted:
      let result = pendingLocationResult
      pendingLocationResult = nil
      result?(FlutterError(code: "LOCATION_PERMISSION", message: "Die Standortberechtigung wurde abgelehnt. Bitte erlaube den Standort in den App-Einstellungen.", details: nil))
    default:
      break
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    let result = pendingLocationResult
    pendingLocationResult = nil
    locationManager = nil
    result?(["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    let result = pendingLocationResult
    pendingLocationResult = nil
    locationManager = nil
    result?(FlutterError(code: "LOCATION_UNAVAILABLE", message: "Der aktuelle Standort konnte nicht ermittelt werden.", details: error.localizedDescription))
  }
}
