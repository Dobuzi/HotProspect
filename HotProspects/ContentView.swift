//
//  ContentView.swift
//  HotProspects
//
//  Created by 김종원 on 2020/11/08.
//

import SwiftUI

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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            VStack {
                EditView()
                DisplayView()
            }
            .onTapGesture(count: 1, perform: {
                self.selectedTab = 1
            })
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
