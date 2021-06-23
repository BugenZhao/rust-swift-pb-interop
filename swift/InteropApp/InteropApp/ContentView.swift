//
//  ContentView.swift
//  InteropApp
//
//  Created by Bugen Zhao on 6/23/21.
//

import SwiftUI

func greeting(_ verb: String, _ name: String) -> String {
    let greetingReq = GreetingRequest.with {
        $0.verb = verb
        $0.name = name
    }
    let req = Request.with {
        $0.greeting = greetingReq
    }
    let res: GreetingResponse = rustCall(req)
    return res.text
}

func sleep(seconds: Int, closure: @escaping (String) -> Void) {
    let sleepReq = SleepRequest.with {
        $0.millis = UInt64(seconds * 1000)
    }
    let req = Request.with {
        $0.sleep = sleepReq
    }
    rustCallAsync(req) { (res: SleepResponse) in
        closure(res.text)
    }
}


struct ContentView: View {
    @State private var verb = "Hello"
    @State private var name = "Bugen"
    @State private var sleepTime = 3
    @State private var awakeMessage: String? = nil
    @State private var sleeping = false

    var body: some View {
        let greet = greeting($verb.wrappedValue, $name.wrappedValue)

        VStack {
            HStack {
                TextField("Hello", text: $verb)
                TextField("Your name", text: $name)
                Spacer()
                Text(greet)
                    .multilineTextAlignment(.trailing)
            }
            HStack {
                Stepper("\(sleepTime)", value: $sleepTime, in: 0...10)
                Button("sleep") {
                    sleeping = true
                    awakeMessage = nil
                    sleep(seconds: sleepTime) { text in
                        awakeMessage = "Rust: " + text
                        sleeping = false
                    }
                }.disabled(sleeping)
                Spacer()
                if (sleeping) {
                    ProgressView()
                        .frame(width: 16.0, height: 16.0)
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.5)
                } else {
                    Text(awakeMessage ?? "...")
                }
            }
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
