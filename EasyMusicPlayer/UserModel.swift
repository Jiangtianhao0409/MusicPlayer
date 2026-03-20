// UserModel.swift
import Foundation
import SwiftData

@Model
final class User {
    // 🔑 唯一标识
    var id: UUID
    
    // 👤 账号信息
    var username: String          // 登录用的用户名（唯一）
    var email: String?            // 可选邮箱（用于找回密码、通知等）
    
    // 🔒 安全相关
    var passwordHash: String      // 存储密码的哈希值（永远不要存明文！）
    var salt: String?             // 可选：盐值（如果使用加盐哈希）
    
    // 📅 时间戳
    var createdAt: Date           // 注册时间
    var lastLoginAt: Date?        // 最后登录时间
    
    
    // ----------------------------
    // MARK: - 初始化方法
    // ----------------------------
    
    /// 用于注册新用户（ViewModel 调用）
    init(
        username: String,
        email: String? = nil,
        passwordHash: String,
        salt: String? = nil
    ) {
        self.id = UUID()
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
        self.salt = salt
        self.createdAt = Date()
        self.lastLoginAt = nil
     
    }
    
    /// 用于从数据库恢复（SwiftData 自动调用，保留默认 init）
    init() {
        self.id = UUID()
        self.username = ""
        self.email = nil
        self.passwordHash = ""
        self.salt = nil
        self.createdAt = Date()
        self.lastLoginAt = nil
    }
}
