import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager() // 位置情報を取得するためのオブジェクト
    @Published var userLocation: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125) // 東京駅   Debug
    //@Published var userLocation: CLLocationCoordinate2D? // 現在地の緯度経度を保持するための変数
    @Published var heading: CLHeading? // デバイスの向きを保持するための変数

    override init() {
        super.init()
        //自分の位置を東京駅に設定   Debug
        //userLocation = CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125)
        locationManager.delegate = self // デリゲートを設定して位置情報の更新を受け取る
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // 最高の精度で位置情報を取得
        locationManager.requestWhenInUseAuthorization() // 位置情報の使用許可をリクエスト
        locationManager.startUpdatingLocation() // 位置情報の更新を開始
        locationManager.startUpdatingHeading() // デバイスの向きの更新を開始
    }

    // 現在地が更新されたときに呼ばれるデリゲートメソッド
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            userLocation = location.coordinate // 取得した現在地をuserLocationに保存
        }
    }

    // デバイスの方位が更新されたときに呼ばれるデリゲートメソッド
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading // 取得した方位情報をheadingに保存
    }
}
