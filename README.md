# SwiftUI  and Nodejs communication

This article we will learn how we communicate swift and node js on socket. We will make a simple app together. Before all this, you need to know enough js lang knowledge how to use and what is socket server.

## Installing node js (Skip this step If you installed nodejs)

To use node js on your local [download](https://nodejs.org/en/) here

Make sure you install and ready use node js in your computer, open your terminal write below. If you don’t get any error, everything is ready to development.

```swift
> node -v
// v14.16.0
```

We will make a reel world application in this article communicate swift and socket-io. Basically, our app connect local socket server and listen it on `fetched-curreny-list` channel. If get any response on channel reload list again. Every minute app keep try to fetch for new list from server. Server listen to app on `get-new-currency-list` If get any request response a new list to app

![Simulator Screen Shot - iPhone 13 mini - 2021-12-23 at 22.08.17.png](SwiftUI%20and%20Nodejs%20communication%20fce1005cbbe449729082f9c334837240/Simulator_Screen_Shot_-_iPhone_13_mini_-_2021-12-23_at_22.08.17.png)

He we go...

## 1. Setup application

To create SwiftUI app, choose app and set a name 

![Choos app](SwiftUI%20and%20Nodejs%20communication%20fce1005cbbe449729082f9c334837240/Screen_Shot_2021-12-19_at_13.41.11.png)

Choos app

Set **Interface SwiftUI** 

![Set interface](SwiftUI%20and%20Nodejs%20communication%20fce1005cbbe449729082f9c334837240/Screen_Shot_2021-12-19_at_12.24.11.png)

Set interface

We will use `Socket.IO-Client-Swift`  for connect socket server. We will use **cocopods** for this. On main folder run below code to setup cocopods

```bash
> pod init
```

After replace `Podfile`  with this

```ruby
# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'socket-demo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  pod 'Socket.IO-Client-Swift', '~> 15.2.0'
  # Pods for socket-demo

end
```

And run

```bash
> pod install
```

App side is ready to coding now!

## 2. Setup server

To create socket server run below code on desktop

```bash
> mkdir socketdemo && cd socketdemo && touch server.js && npm init
```

Replace your `package.js` with this

```json
{
  "name": "socketdemo",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "ISC",
  "homepage": "",
  "dependencies": {
    "express": "^4.17.1",
    "socket.io": "^4.2.0",
		"node-fetch": "^3.1.0"
  }
}
```

To install dependencies

```bash
> touch index.js && npm install
```

Socket side is ready to coding too!

### 3. Let build our app

We will use [coinmarketcap](https://coinmarketcap.com/) data to fetch currencies. Don’t forget get your api key on  [here](https://coinmarketcap.com/api/)

From server side put below code in `index.js`

```jsx
import express from "express";
import { createServer } from "http";
import { Server } from "socket.io";
import fetch from "node-fetch";

const app = express();
const server = createServer(app);
const io = new Server(server, {
  allowEIO3: true,
});

const apiKey = "{{ API_KEY }}"; // https://coinmarketcap.com/api/
const limit = 10;
const currencyListUrl = `https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest?CMC_PRO_API_KEY=${apiKey}&limit=${limit}`;

io.on("connection", (socket) => {
  console.log("a user connected");
  fetchList(socket);
  socket.on("get-new-currency-list", () => {
    fetchList(socket);
  });
});

const fetchList = (socket) => {
  fetchCurrencList().then((currencyList) => {
    socket.emit("fetched-curreny-list", { list: currencyList });
  });
};

const fetchCurrencList = () =>
  new Promise((resolve, reject) => {
    console.log("List fetched");
    fetch(currencyListUrl)
      .then((res) => res.json())
      .then((res) => resolve(res))
      .catch((error) => reject(error));
  });

server.listen(5000, () => {
  console.log("socket run on 5000: http://localhost:5000");
});
```

To connect server from app side use below code. We are using `CurrencyList` data  to parse server side response

```swift
//
//  CurrencyListModel.swift
//  socket-demo
//
//  Created by Erdem ILDIZ 
//

import Foundation

// MARK: - CurrencyList
struct CurrencyList: Codable {
    let data: [CurrencyItem]
}

// MARK: - Datum
struct CurrencyItem: Codable {
    let id: Int
    let name, symbol, slug: String
    let lastUpdated: String
    let quote: Quote

    enum CodingKeys: String, CodingKey {
        case id, name, symbol, slug
        case lastUpdated = "last_updated"
        case quote
    }
}

// MARK: - Quote
struct Quote: Codable {
    let price: Price

    enum CodingKeys: String, CodingKey {
        case price = "USD"
    }
}

// MARK: - Usd
struct Price: Codable {
    let priceValue, volume24H : Double
    let lastUpdated: String

    enum CodingKeys: String, CodingKey {
        case priceValue = "price"
        case volume24H = "volume_24h"
        case lastUpdated = "last_updated"
    }
}
```

Use below code for UI. We will connect localserver on `http://localhost:5000`

```swift
//
//  ContentView.swift
//  socket-demo
//
//  Created by Erdem ILDIZ 
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
```

In this article we communicate Swift and Nodejs on socket.