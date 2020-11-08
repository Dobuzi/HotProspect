//
//  ContentView.swift
//  HotProspects
//
//  Created by 김종원 on 2020/11/08.
//

import UserNotifications
import SwiftUI

class DelayedUpdater: ObservableObject {
    var value = 0 {
        willSet {
            objectWillChange.send()
        }
    }
    
    init() {
        for i in 1...10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
                self.value += 1
            }
        }
    }
}

class User: ObservableObject {
    @Published var name = "Taylor Swift"
}

struct EditView: View {
    @EnvironmentObject var user: User
    
    var body: some View {
        TextField("Name", text: $user.name)
            .frame(width: 100)
    }
}

struct DisplayView: View {
    @EnvironmentObject var user: User
    
    var body: some View {
        Text(user.name)
    }
}

struct ContentView: View {
    let user = User()
    
    @State private var appleData = ""
    @State private var selectedTab = 0
    @State private var backgroundColor = Color.red
    
    @ObservedObject var updater = DelayedUpdater()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Image("example")
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .padding()
                .frame(width: 200)
                .background(backgroundColor)
                .ignoresSafeArea()
                .contextMenu {
                    Button(action: {
                        withAnimation {
                            self.backgroundColor = .red
                        }
                    }, label: {
                        Label("RED", systemImage: self.backgroundColor == .red ? "checkmark.circle.fill" : "")
                    })
                    Button(action: {
                        withAnimation {
                            self.backgroundColor = .green
                        }
                    }, label: {
                        Label("GREEN", systemImage: self.backgroundColor == .green ? "checkmark.circle.fill" : "")
                    })
                    Button(action: {
                        withAnimation {
                            self.backgroundColor = .blue
                        }
                    }, label: {
                        Label("BLUE", systemImage: self.backgroundColor == .blue ? "checkmark.circle.fill" : "")
                    })
                }
            .tabItem {
                Label("One", systemImage: "star")
            }
            .tag(0)
            
            Text(appleData)
                .background(Color.yellow)
                .onAppear {
                    self.fetchData(from: "https://www.apple.com/kr") { result in
                        switch result {
                        case .success(let str):
                            appleData = str
                            print(str)
                        case .failure(let error):
                            switch error {
                            case .badURL:
                                print("Bad URL")
                            case .requestFailed:
                                print("Network problems")
                            default:
                                print("Unknown error")
                            }
                        }
                    }
                }
            .tabItem {
                Label("Two", systemImage: "star.fill")
            }
                .tag(1)
        }
        .environmentObject(user)
    }
    
    func fetchData(from urlString: String, completion: @escaping (Result<String, NetworkError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.badURL))
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    let stringData = String(decoding: data, as: UTF8.self)
                    completion(.success(stringData))
                } else if error != nil {
                    completion(.failure(.requestFailed))
                } else {
                    completion(.failure(.unknown))
                }
                
            }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static let user = User()
    static var previews: some View {
        ContentView()
            .environmentObject(user)
    }
}

enum NetworkError: Error {
    case badURL, requestFailed, unknown
}
