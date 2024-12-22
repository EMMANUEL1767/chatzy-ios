//
//  UserDefaults+Extension.swift
//  chatzy
//
//  Created by Emmanuel Biju on 21/12/24.
//

import Foundation

extension UserDefaults {
    private enum Keys {
        static let userId = "userId"
        static let authToken = "authToken"
    }
    
    var userId: Int? {
        get { object(forKey: Keys.userId) as? Int }
        set { setValue(newValue, forKey: Keys.userId) }
    }
    
    var authToken: String? {
        get { string(forKey: Keys.authToken) }
        set { setValue(newValue, forKey: Keys.authToken) }
    }
    
    func clearAuthData() {
        removeObject(forKey: Keys.userId)
        removeObject(forKey: Keys.authToken)
    }
}
