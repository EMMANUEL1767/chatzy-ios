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
            .navigationTitle("Chat App")
        }
    }
}

// Views/Authentication/LoginView.swift

#Preview {
    AuthView()
}
