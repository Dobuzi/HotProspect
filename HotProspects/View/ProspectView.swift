//
//  ProspectView.swift
//  HotProspects
//
//  Created by 김종원 on 2020/11/08.
//

import SwiftUI
import CodeScanner
import UserNotifications

enum FilterType {
    case none, contacted, uncontacted
}

enum SortingType {
    case none, name, emailAddress, mostRecent
}

struct ProspectView: View {
    @State private var isShowingScanner = false
    @State private var showingActionSheet = false
    @EnvironmentObject var prospects: Prospects
    let filter: FilterType
    @State var sortingCondition: SortingType = .none
    var filteredProspects: [Prospect] {
        switch filter {
        case .none:
            return prospects.people
        case .contacted:
            return prospects.people.filter { $0.isContacted }
        case .uncontacted:
            return prospects.people.filter { !$0.isContacted }
        }
    }
    var sortedProspects: [Prospect] {
        switch sortingCondition {
        case .none:
            return filteredProspects
        case .name:
            return filteredProspects.sorted(by: { lhs, rhs in
                lhs.name < rhs.name
            })
        case .emailAddress:
            return filteredProspects.sorted(by: { lhs, rhs in
                lhs.emailAddress < rhs.emailAddress
            })
        case .mostRecent:
            return filteredProspects.sorted(by: { lhs, rhs in
                lhs.enrollDate > rhs.enrollDate
            })
        }
    }
    
    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Contacted people"
        case .uncontacted:
            return "Uncontacted people"
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sortedProspects) { prospect in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(prospect.name)
                                .font(.headline)
                            Text(prospect.emailAddress)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if filter == .none {
                            Image(systemName: prospect.isContacted ? "person.fill.checkmark" : "person.fill.questionmark")
                                .foregroundColor(prospect.isContacted ? .blue : .red)
                        }
                    }
                    .contextMenu {
                        Button(prospect.isContacted ? "Mark Uncontacted" : "Mark Contacted") {
                            self.prospects.toggle(prospect)
                        }
                        if !prospect.isContacted {
                            Button("Remind Me") {
                                self.addNotification(for: prospect)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(title)
            .navigationBarItems(leading: Button(action: {
                self.showingActionSheet = true
            }) {
                Label("Sort", systemImage: "arrow.up.arrow.down.square")
            }, trailing: Button(action: {
                self.isShowingScanner = true
            }) {
                Label("Scan", systemImage: "qrcode.viewfinder")
            })
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.qr],
                                simulatedData: "Dobuzi\ndobuji@kakao.com",
                                completion: self.handleScan)
            }
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(title: Text("Sorting conditions"), buttons: [
                    .default(Text("Name"), action: {
                        sortingCondition = .name
                    }),
                    .default(Text("Email Address"), action: {
                        sortingCondition = .emailAddress
                    }),
                    .default(Text("Most Recent"), action: {
                        sortingCondition = .mostRecent
                    }),
                    .cancel()
                ])
            }
        }
    }
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        self.isShowingScanner = false
        switch result {
        case .success(let code):
            let details = code.components(separatedBy: "\n")
            guard details.count == 2 else { return }
            
            let person = Prospect()
            person.name = details[0]
            person.emailAddress = details[1]
            
            self.prospects.add(person)
        case .failure(let error):
            switch error {
            case .badInput:
                print("bad input")
            case .badOutput:
                print("bad output")
            }
            print("Scanning failed")
        }
    }
    
    func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()
        
        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default
            
//            var dateComponents = DateComponents()
//            dateComponents.hour = 9
//            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString,
                                                content: content,
                                                trigger: trigger)
            center.add(request)
        }
        
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        addRequest()
                    } else {
                        print("D'oh")
                    }
                }
            }
        }
    }
}

struct ProspectView_Previews: PreviewProvider {
    static var prospects = Prospects()
    static var previews: some View {
        ProspectView(filter: .none)
            .environmentObject(prospects)
    }
}
