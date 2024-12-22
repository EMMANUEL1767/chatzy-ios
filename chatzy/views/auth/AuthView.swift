//
//  AuthView.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import SwiftUI

struct AuthView: View {
    @State private var isShowingLogin = true
    
    var body: some View {
        NavigationView {
            VStack {
                Image("chatzy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100, alignment: .center)
                    
                Text("Chatzy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Picker("", selection: $isShowingLogin) {
                    Text("Login").tag(true)
                    Text("Register").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if isShowingLogin {
                    LoginView()
                } else {
                    RegisterView()
                }
                
                
            }
        }
    }
}

// Views/Authentication/LoginView.swift

#Preview {
    AuthView()
}
