//
//  TypingDotsView.swift
//  chatzy
//
//  Created by Emmanuel Biju on 22/12/24.
//

import SwiftUI

struct TypingDotsView: View {
    @State private var showFirstDot = false
    @State private var showSecondDot = false
    @State private var showThirdDot = false
    
    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(Color.gray)
                .frame(width: 4, height: 4)
                .opacity(showFirstDot ? 1 : 0.3)
            
            Circle()
                .fill(Color.gray)
                .frame(width: 4, height: 4)
                .opacity(showSecondDot ? 1 : 0.3)
            
            Circle()
                .fill(Color.gray)
                .frame(width: 4, height: 4)
                .opacity(showThirdDot ? 1 : 0.3)
        }
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        let animation = Animation.easeInOut(duration: 0.4)
        
        withAnimation(animation.repeatForever()) {
            showFirstDot.toggle()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(animation.repeatForever()) {
                showSecondDot.toggle()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(animation.repeatForever()) {
                showThirdDot.toggle()
            }
        }
    }
}

#Preview {
    TypingDotsView()
}
