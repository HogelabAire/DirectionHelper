import SwiftUI
import MapKit
import UIKit
import CoreLocation

struct MapView: UIViewRepresentable {
    @Binding var mapView: MKMapView // MapViewをバインディングとして渡す
    @Binding var userLocation: CLLocationCoordinate2D? // 現在地をバインディングとして保持
    @Binding var heading: CLHeading? // デバイスの向きをバインディングとして保持
    @Binding var selectedMapItem: MKMapItem? // タップされたピンの情報を保持するバインディング

    func makeUIView(context: Context) -> MKMapView {
        mapView.showsUserLocation = true // 現在地をマップに表示
        mapView.userTrackingMode = .follow // ユーザーの位置と向きに追従
        mapView.delegate = context.coordinator // デリゲートを設定
        
        // 東京駅を初期表示するための設定   Debug
        //let tokyoStationCoordinate = CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125)
        //let region = MKCoordinateRegion(center: tokyoStationCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        //mapView.setRegion(region, animated: false) // 東京駅を初期位置に設定
        
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        if let heading = heading {
            let camera = view.camera
            camera.heading = heading.magneticHeading // スマホの方位に基づいてマップの向きを更新
            view.setCamera(camera, animated: true)
            
            // 現在地とピンの方向のなす角度を出力
            if let userLocation = userLocation {
                // ユーザーの現在地以外のアノテーションをフィルタリング
                let nonUserAnnotations = view.annotations.filter { !($0 is MKUserLocation) }
                
                if nonUserAnnotations.count >= 1 {
                    
                    let annotation = nonUserAnnotations[0]
                    
                    // 2つ目のアノテーションの座標を使用して処理を行う
                    let pinCoordinate = annotation.coordinate
                    let pinBearing = calculateBearing(from: userLocation, to: pinCoordinate)
                    let deviceHeading = heading.magneticHeading
                    
                    // ピンの方位とデバイスの方位の差（なす角度）を計算
                    var angleDifference = pinBearing - deviceHeading
                    angleDifference = normalizeAngle(angleDifference) // 角度を 0〜360° に正規化
                    
                    //print("現在地と2つ目のピンの方向のなす角度: \(angleDifference)度")
                    // 角度差が -10° から 10° の範囲内かチェック
                    if angleDifference >= -10 && angleDifference <= 10 {
                        triggerHapticFeedback() // 振動を発生させる
                        print("スマホがピンの方向を向いています！振動を発生させました。")
                    }
                }
            }
        }
    }
    // 角度を -180° から 180° に正規化する
    func normalizeAngle(_ angle: Double) -> Double {
        var normalizedAngle = angle.truncatingRemainder(dividingBy: 360) // 360度範囲に収める
        if normalizedAngle > 180 {
            normalizedAngle -= 360 // 180度より大きい場合、負の範囲に移動
        } else if normalizedAngle < -180 {
            normalizedAngle += 360 // -180度より小さい場合、正の範囲に移動
        }
        return normalizedAngle
    }
    
    // 振動を発生させる関数
    func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    // デリゲート用のCoordinatorクラス
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        // ピンがタップされた時の処理
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation else { return }

            // ピンの座標からMKMapItemを作成
            let placemark = MKPlacemark(coordinate: annotation.coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = annotation.title ?? "不明な場所"

            // 選択されたピンを親ビューに伝える
            parent.selectedMapItem = mapItem
        }
    }
    // 2地点間の方位（角度）を計算
    func calculateBearing(from userLocation: CLLocationCoordinate2D, to pinLocation: CLLocationCoordinate2D) -> Double {
        let lat1 = userLocation.latitude * .pi / 180
        let lon1 = userLocation.longitude * .pi / 180
        let lat2 = pinLocation.latitude * .pi / 180
        let lon2 = pinLocation.longitude * .pi / 180

        let deltaLon = lon2 - lon1
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let bearing = atan2(y, x)
        
        return bearing * 180 / .pi
    }
}
