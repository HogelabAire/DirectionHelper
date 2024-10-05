import Foundation
import CoreLocation
import MapKit

// お気に入りのデータを保存するための構造体
struct FavoriteLocation: Codable {
    var name: String
    var latitude: Double
    var longitude: Double
}

extension FavoriteLocation {
    // MKMapItemに変換する
    var mapItem: MKMapItem {
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        return mapItem
    }

    // MKMapItemからお気に入りのデータを作る
    init(mapItem: MKMapItem) {
        self.name = mapItem.name ?? "不明な場所"
        self.latitude = mapItem.placemark.coordinate.latitude
        self.longitude = mapItem.placemark.coordinate.longitude
    }
}
