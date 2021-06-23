//
//  ContentView.swift
//  InteropApp
//
//  Created by Bugen Zhao on 6/23/21.
//

import SwiftUI

struct ContentView: View {
    @State private var verb = "Hello"
    @State private var name = "Bugen"

    var body: some View {
        let greet = greeting($verb.wrappedValue, $name.wrappedValue)

        VStack {
            HStack {
                TextField("Hello", text: $verb)
                TextField("Your name", text: $name)
            }
            Text(greet)
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


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
