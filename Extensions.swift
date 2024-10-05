import MapKit
import CoreLocation

// 現在地から目的地までの距離を計算
func calculateDistance(from userLocation: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
    let startLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
    let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
    return startLocation.distance(from: destinationLocation)
}

// 現在地と検索結果のピンを含む矩形領域を計算
func calculateBoundingRegion(userLocation: CLLocationCoordinate2D, searchLocation: CLLocationCoordinate2D) -> MKCoordinateRegion {
    let latitudes = [userLocation.latitude, searchLocation.latitude]
    let longitudes = [userLocation.longitude, searchLocation.longitude]

    let minLatitude = latitudes.min()!
    let maxLatitude = latitudes.max()!
    let minLongitude = longitudes.min()!
    let maxLongitude = longitudes.max()!

    let center = CLLocationCoordinate2D(
        latitude: (minLatitude + maxLatitude) / 2,
        longitude: (minLongitude + maxLongitude) / 2
    )
    let span = MKCoordinateSpan(
        latitudeDelta: (maxLatitude - minLatitude) * 1.5,
        longitudeDelta: (maxLongitude - minLongitude) * 1.5
    )

    return MKCoordinateRegion(center: center, span: span)
}
