//
//  ContentView.swift
//  socket-demo
//
//  Created by Erdem ILDIZ on 19.12.2021.
//

import SwiftUI
import SocketIO

enum SocketConfig {
    static let url = "http://localhost:5000"
}

struct ContentView: View {
    @State var currencyList: [CurrencyItem] = []
    
    let socketManager = SocketManager(
        socketURL: URL(string: SocketConfig.url)!,
        config: [.log(true), .compress])
    
    var body: some View {
        NavigationView {
            List {
                ForEach(currencyList, id: \.id) { currency in
                    HStack {
                        Text(currency.name)
                            .font(.system(size: 16))
                        Spacer()
                        Text(currencyFormatting(price: currency.quote.price.priceValue))
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .bold, design: .default))
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Currency List")
        }
        .onAppear {
            setupSocketConneciton()
        }
    }
}


extension ContentView {
    
    private func setupSocketConneciton() {
        let socket = socketManager.defaultSocket
        socket.on(clientEvent: .connect) { data, ack in
            socket.on("fetched-curreny-list") { data, ack in
                guard let receicedData = data[0] as? NSMutableDictionary,
                let list = receicedData.object(forKey: "list") as? NSDictionary else {
                  return
                }
                // Decode received response
                do {
                    let listData = try JSONSerialization.data(withJSONObject: list, options: .prettyPrinted)
                    let currencyData = try JSONDecoder().decode(CurrencyList.self, from: listData)
                    self.currencyList = currencyData.data
                } catch{
                    print(error.localizedDescription)
                }
                // Fetch currency list every minute
                Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                    socket.emit("get-new-currency-list", with: [])
                }
            }
        }
        
        socket.connect()
    }
    
    private func currencyFormatting(price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
         if let str = formatter.string(for: price) {
            return str
        }
        return ""
     }
}
