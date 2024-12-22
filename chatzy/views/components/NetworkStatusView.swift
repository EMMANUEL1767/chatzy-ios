//
//  NetworkStatusView.swift
//  chatzy
//
//  Created by Emmanuel Biju on 22/12/24.
//

import SwiftUI

struct NetworkStatusView: View {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        if !networkMonitor.isConnected {
            VStack {
                Text("No Internet Connection")
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(Color.red)
                    .cornerRadius(20)
            }
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.2))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview {
    NetworkStatusView()
}
