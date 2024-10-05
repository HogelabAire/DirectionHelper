import SwiftUI
import MapKit



struct ContentView: View {
    @StateObject private var locationManager = LocationManager() // LocationManagerを初期化して位置情報を管理
    @State private var searchText: String = "" // 検索ボックス用の入力テキスト
    @State private var searchResults: [(MKMapItem, Double)] = [] // 検索結果と距離をペアで保持する配列
    @State private var mapView = MKMapView() // MapViewのインスタンスを作成
    @State private var shortcuts: [Shortcut] = [] // ショートカットリスト
    @State private var newShortcutName = "" // 新しいショートカットの名前
    @State private var favorites: [MKMapItem] = [] // お気に入りリスト
    @State private var selectedMapItem: MKMapItem? // タップされたピンの情報
    @State private var showingAlert = false // アラート表示用の状態
    @State private var pinHistory: [MKMapItem] = [] // ピンを置いた場所を保存するリスト
    @State private var displayedList: DisplayedList = .searchResults // 表示するリストを管理
    
    let tokyoStationCoordinate = CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125) // 東京駅の座標   Debug

    enum DisplayedList {
        case favorites
        case pinHistory
        case searchResults
    }

    var body: some View {
        VStack {
            // マップを上に配置
            GeometryReader { geometry in
                if let userLocation = locationManager.userLocation {
                    MapView(mapView: $mapView, userLocation: $locationManager.userLocation, heading: $locationManager.heading, selectedMapItem: $selectedMapItem)
                        .frame(width: geometry.size.width, height: geometry.size.width) // 正方形のマップ
                        .edgesIgnoringSafeArea(.top) // 上部の余白を無視
                } else {
                    Text("現在地を取得中...")
                        .font(.headline)
                        .frame(width: geometry.size.width, height: geometry.size.width) // 正方形のスペースを確保
                }
            }
            
            // お気に入りボタンを右寄せ
            HStack {
                Spacer() // 左側にスペースを空ける
                // リセットボタン
                Button(action: {
                    // リセットボタンのアクション: 検索結果をリセット
                    searchText = "" // 検索ボックスのテキストをリセット
                    searchResults = [] // 検索結果をクリア
                    // マップ上のピンを削除
                    mapView.removeAnnotations(mapView.annotations)
                    
                    // 現在地を取得してマップの中心に設定
                    if let userLocation = locationManager.userLocation {
                        let userCoordinate = userLocation // 現在地の座標
                        let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // ズーム範囲
                        let defaultRegion = MKCoordinateRegion(center: userCoordinate, span: defaultSpan)
                        mapView.setRegion(defaultRegion, animated: false) // 現在地を中心にマップを戻す
                    }
                    displayedList = .searchResults
                }) {
                    Text("リセット")
                        .padding(.vertical, 5)
                        .padding(.horizontal, 15)
                        .background(Color.red.opacity(0.4)) // リセットボタンは赤系の背景で目立たせる
                        .foregroundColor(.black) // テキストを黒色に変更
                        .cornerRadius(5)
                }
                // 検索履歴ボタン
                Button(action: {
                    displayedList = .pinHistory // 検索履歴を表示
                }) {
                    Text("検索履歴")
                        .padding(.vertical, 5)
                        .padding(.horizontal, 15)
                        .background(Color.blue.opacity(0.4))
                        .foregroundColor(.black)
                        .cornerRadius(5)
                }
                
                // お気に入りボタン
                Button(action: {
                    displayedList = .favorites // お気に入りを表示
                }) {
                    Text("お気に入り")
                        .padding(.vertical, 5)
                        .padding(.horizontal, 15)
                        .background(Color.yellow.opacity(0.7))
                        .foregroundColor(.black)
                        .cornerRadius(5)
                }
            }
            .padding(.horizontal) // ボタンの左右に余白をつける
            
            
            // 新しいショートカットを作るテキストボックス
            TextField("新しいショートカットを作る", text: $newShortcutName, prompt: Text("ショートカットを作る"))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.leading, .trailing])
                .onSubmit {
                    if !newShortcutName.isEmpty {
                        let newShortcut = Shortcut(name: newShortcutName, keyword: newShortcutName)
                        shortcuts.append(newShortcut)
                        saveShortcuts() // ショートカットを保存
                        performSearch(for: newShortcut.keyword) // ショートカット作成と同時に検索を実行
                        newShortcutName = "" // 入力フィールドをクリア
                    }
                }
            
            // ショートカット表示エリア
            ScrollView(.horizontal) {
                HStack {
                    ForEach(shortcuts.indices, id: \.self) { index in
                        Button(action: {
                            searchText = shortcuts[index].keyword
                            performSearch(for: shortcuts[index].keyword)
                        }) {
                            Text(shortcuts[index].name)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 15)
                                .background(Color.gray.opacity(0.4)) // グレー色で目立たなく
                                .foregroundColor(.black) // テキストを黒色に変更
                                .cornerRadius(5)
                        }
                        .contextMenu {
                            Button(action: {
                                removeShortcut(at: index)
                            }) {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 10)
            
            // リスト表示
            List {
                switch displayedList {
                case .favorites:
                    ForEach(favorites.indices, id: \.self) { index in
                        if let userLocation = locationManager.userLocation {
                            let distance = calculateDistance(from: userLocation, to: favorites[index].placemark.coordinate)
                            Button(action: {
                                placePin(on: favorites[index])
                                let boundingRegion = calculateBoundingRegion(userLocation: userLocation, searchLocation: favorites[index].placemark.coordinate)
                                mapView.setRegion(boundingRegion, animated: false)
                            }) {
                                HStack {
                                    Text(favorites[index].name ?? "不明な場所")
                                    Spacer()
                                    Text("\(Int(distance)) m")
                                }
                            }
                        }
                    }
                    .onDelete(perform: removeFavorite)

                    case .pinHistory:
                        ForEach(pinHistory.indices, id: \.self) { index in
                            if let userLocation = locationManager.userLocation {
                                let distance = calculateDistance(from: userLocation, to: pinHistory[index].placemark.coordinate)
                                Button(action: {
                                    placePin(on: pinHistory[index])
                                    let boundingRegion = calculateBoundingRegion(userLocation: userLocation, searchLocation: pinHistory[index].placemark.coordinate)
                                    mapView.setRegion(boundingRegion, animated: false)
                                }) {
                                    HStack {
                                        Text(pinHistory[index].name ?? "不明な場所")
                                        Spacer()
                                        Text("\(Int(distance)) m")
                                    }
                                }
                            }
                        }
                        .onDelete(perform: removePinHistoryItem)

                    case .searchResults:
                        // 検索結果リストの表示
                        ForEach(searchResults.indices, id: \.self) { index in
                            Button(action: {
                                placePin(on: searchResults[index].0)
                                if let userLocation = locationManager.userLocation {
                                    let boundingRegion = calculateBoundingRegion(userLocation: userLocation, searchLocation: searchResults[index].0.placemark.coordinate)
                                    mapView.setRegion(boundingRegion, animated: false)
                                }
                            }) {
                                HStack {
                                    Text(searchResults[index].0.name ?? "不明な場所")
                                    Spacer()
                                    Text("\(Int(searchResults[index].1)) m")
                                }
                            }
                        }
                        .onDelete(perform: deleteSearchResult)
                        .onMove(perform: moveSearchResult)
                    }
                }
                .frame(height: 200)
                .toolbar {
                    EditButton()
                }
            }

            
            
        // 検索ボックスを下に配置
        TextField("場所を検索", text: $searchText, prompt: Text("目的地を検索"))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            .onSubmit {
                performSearch(for: searchText)
            }
        
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("お気に入りに追加しますか？"),
                    message: Text(selectedMapItem?.name ?? "不明な場所"),
                    primaryButton: .default(Text("はい"), action: {
                        if let selectedItem = selectedMapItem {
                            addToFavorites(newItem: selectedItem)
                        }
                        print("test") // ここが1回だけ呼ばれる
                        showingAlert = false
                    }),
                    secondaryButton: .cancel(Text("いいえ"), action: {
                        showingAlert = false
                    })
                )
            }
        .onAppear {
            loadShortcuts()
            loadFavorites()
            loadPinHistory()
        }
        .onChange(of: selectedMapItem) { newValue in
            if let newValue = newValue {
                showingAlert = true
            } else {
                showingAlert = false
            }
        }
    }
    
    // 検索結果を削除する関数
    private func deleteSearchResult(at offsets: IndexSet) {
        searchResults.remove(atOffsets: offsets)
    }
    
    // お気に入りリストを削除する関数
    private func removeFavorite(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
        saveFavorites()
    }
    // 検索履歴の項目を削除する関数
    private func removePinHistoryItem(at offsets: IndexSet) {
        pinHistory.remove(atOffsets: offsets)
        savePinHistory()
    }
    // 検索結果の順番を変更する関数
    private func moveSearchResult(from source: IndexSet, to destination: Int) {
        searchResults.move(fromOffsets: source, toOffset: destination) // 順番を変更
    }

    // お気に入りリストを更新
    private func addToFavorites(newItem: MKMapItem) {
        if !favorites.contains(where: { $0.placemark.coordinate.latitude == newItem.placemark.coordinate.latitude && $0.placemark.coordinate.longitude == newItem.placemark.coordinate.longitude }) {
            favorites.append(newItem)
            saveFavorites() // 新しいお気に入りを保存
            print("\(newItem.name ?? "不明な場所") がお気に入りに追加されました")
        } else {
            print("\(newItem.name ?? "不明な場所") は既にお気に入りに追加されています")
        }
    }

    // ショートカットを保存する関数
    private func saveShortcuts() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(shortcuts) {
            UserDefaults.standard.set(encoded, forKey: "shortcuts")
        }
    }
    // pinHistoryをUserDefaultsに保存する処理
    private func savePinHistory() {
        let encoder = JSONEncoder()
        let favoriteLocations = pinHistory.map { FavoriteLocation(mapItem: $0) } // MKMapItemを保存可能な形式に変換
        if let encoded = try? encoder.encode(favoriteLocations) {
            UserDefaults.standard.set(encoded, forKey: "pinHistory")
            print("ピン履歴が保存されました")
        }
    }

    // ショートカットを読み込む関数
    private func loadShortcuts() {
        if let savedShortcuts = UserDefaults.standard.data(forKey: "shortcuts") {
            let decoder = JSONDecoder()
            if let loadedShortcuts = try? decoder.decode([Shortcut].self, from: savedShortcuts) {
                shortcuts = loadedShortcuts
            }
        }
        // デフォルトで「コンビニ」が無ければ追加
        if shortcuts.isEmpty {
            shortcuts.append(Shortcut(name: "コンビニ", keyword: "コンビニ"))
            shortcuts.append(Shortcut(name: "駅", keyword: "駅"))
        }
    }
    // pinHistoryをUserDefaultsから読み込む処理
    private func loadPinHistory() {
        if let savedPinHistory = UserDefaults.standard.data(forKey: "pinHistory") {
            let decoder = JSONDecoder()
            if let loadedPinHistory = try? decoder.decode([FavoriteLocation].self, from: savedPinHistory) {
                pinHistory = loadedPinHistory.map { $0.mapItem } // 保存されたデータからMKMapItemに変換
                print("ピン履歴が読み込まれました: \(pinHistory)")
            } else {
                print("ピン履歴の読み込みに失敗しました")
            }
        }
    }
    
    // UserDefaultsを使ってお気に入りを保存
    private func saveFavorites() {
        let encoder = JSONEncoder()
        let favoriteLocations = favorites.map { FavoriteLocation(mapItem: $0) } // MKMapItemを保存可能な形式に変換
        if let encoded = try? encoder.encode(favoriteLocations) {
            UserDefaults.standard.set(encoded, forKey: "favoriteLocations")
            print("お気に入りが保存されました: \(favoriteLocations)")
        } else {
            print("お気に入りの保存に失敗しました")
        }
    }

    // お気に入りを読み込む
    private func loadFavorites() {
        if let savedFavorites = UserDefaults.standard.data(forKey: "favoriteLocations") {
            let decoder = JSONDecoder()
            if let loadedFavorites = try? decoder.decode([FavoriteLocation].self, from: savedFavorites) {
                favorites = loadedFavorites.map { $0.mapItem } // 保存されたデータからMKMapItemに変換
                print("お気に入りが読み込まれました: \(favorites)")
            } else {
                print("お気に入りの読み込みに失敗しました")
            }
        } else {
            print("お気に入りデータが存在しません")
        }
    }


    // ショートカットを削除する
    private func removeShortcut(at index: Int) {
        shortcuts.remove(at: index)
        saveShortcuts() // ショートカットを削除したら保存
    }

    // 検索処理を実行
    private func performSearch(for keyword: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = keyword

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("検索エラー: \(error.localizedDescription)")
                return
            }

            if let response = response {
                if let userLocation = locationManager.userLocation {
                    searchResults = response.mapItems.map { mapItem in
                        let distance = calculateDistance(from: userLocation, to: mapItem.placemark.coordinate)
                        return (mapItem, distance)
                    }.sorted(by: { $0.1 < $1.1 }) // 距離でソート

                    if let firstResult = searchResults.first {
                        placePin(on: firstResult.0)
                        //Debug   userLocation　⇔ tokyoStationCoordinate
                        let boundingRegion = calculateBoundingRegion(userLocation: userLocation, searchLocation: firstResult.0.placemark.coordinate)
                        mapView.setRegion(boundingRegion, animated: false)
                    }
                }
            }
            // 検索完了後に検索ボックスを空にする
            searchText = ""
            displayedList = .searchResults
        }
    }

    // ピンを刺す処理
    private func placePin(on mapItem: MKMapItem) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = mapItem.placemark.coordinate
        annotation.title = mapItem.name
        print(mapView.annotations)
        mapView.removeAnnotations(mapView.annotations)
        print(mapView.annotations)
        mapView.addAnnotation(annotation)
        print(mapView.annotations)
        
        // 既に同じ場所があれば削除してから新しい方を先頭に追加
        if let existingIndex = pinHistory.firstIndex(where: {
            $0.placemark.coordinate.latitude == mapItem.placemark.coordinate.latitude &&
            $0.placemark.coordinate.longitude == mapItem.placemark.coordinate.longitude
        }) {
            pinHistory.remove(at: existingIndex) // 古いものを削除
            saveFavorites() // 新しいお気に入りを保存
            savePinHistory()
        }

        // 最新の項目を先頭に追加
        pinHistory.insert(mapItem, at: 0)
        // 履歴が30件を超えた場合、古い履歴を削除
        if pinHistory.count > 30 {
            pinHistory.removeLast() // 最後の（最も古い）履歴を削除
        }
        // 履歴を保存
        savePinHistory()
    }
}
