// LoginViewModel.swift
import Foundation
import Combine
import SwiftData
import CryptoKit

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // 密码哈希工具（内嵌或单独文件）
    private func hashPassword(_ plainText: String, salt: String? = nil) -> (hash: String, salt: String) {
        let finalSalt = salt ?? UUID().uuidString
        let combined = plainText + finalSalt
        guard let data = combined.data(using: .utf8) else {
            return ("", finalSalt)
        }
        let hashed = SHA256.hash(data: data)
        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
        return (hashString, finalSalt)
    }

    private func verifyPassword(_ plain: String, storedHash: String, salt: String?) -> Bool {
        let (newHash, _) = hashPassword(plain, salt: salt)
        return newHash == storedHash
    }

    // MARK: - 注册
    func register(
        username: String,
        email: String?,
        password: String,
        modelContext: ModelContext
    ) {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else {
            errorMessage = "账号和密码不能为空"
            return
        }

        isLoading = true
        errorMessage = nil

        // 检查用户名是否已存在
        Task {
            do {
                let descriptor = FetchDescriptor<User>(
                    predicate: #Predicate { user in
                        user.username == username
                    }
                )
                let existing = try await modelContext.fetch(descriptor)
                if !existing.isEmpty {
                    await MainActor.run {
                        self.errorMessage = "该账号已存在"
                        self.isLoading = false
                    }
                    return
                }

                // 哈希密码
                let (hash, salt) = hashPassword(password)

                // 创建新用户
                let newUser = User(
                    username: username,
                    email: email?.isEmpty == true ? nil : email,
                    passwordHash: hash,
                    salt: salt
                )

                modelContext.insert(newUser)
                try await modelContext.save()

                await MainActor.run {
                    print("✅ 注册成功: \(username)")
                    self.isLoading = false
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = "注册失败，请重试"
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - 登录
    func login(
        username: String,
        password: String,
        modelContext: ModelContext
    ) async -> Bool {
        // 1. 输入校验
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty, !password.isEmpty else {
            await MainActor.run {
                self.errorMessage = "账号和密码不能为空"
                self.isLoading = false
            }
            return false
        }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            // 2. 仅根据用户名查询（不再检查 isActive）
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.username == trimmedUsername }
            )
            let users = try await modelContext.fetch(descriptor)

            if let user = users.first {
                // 3. 验证密码
                if verifyPassword(password, storedHash: user.passwordHash, salt: user.salt) {
                    // 4. 更新最后登录时间
                    user.lastLoginAt = Date()
                    try await modelContext.save()

                    await MainActor.run {
                        self.isAuthenticated = true
                        self.isLoading = false
                    }
                    return true
                }
            }

            // 5. 账号不存在或密码错误
            await MainActor.run {
                self.errorMessage = "账号或密码错误"
                self.isLoading = false
            }
            return false

        } catch {
            // 6. 数据库异常
            await MainActor.run {
                self.errorMessage = "登录异常，请稍后重试"
                self.isLoading = false
            }
            return false
        }
    }
    func testPing() async -> String? {
        guard let url = URL(string: "http://39.106.24.44:8080/api/ping") else {
            print("Ping: 无效的 URL")
            return nil
        }
        
        print("正在请求: \(url.absoluteString)") // 👈 打印请求链接
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = json["message"] as? String {
                return "连接成功: \(msg)"
            }
        } catch {
            print("Ping 失败: \(error)")
        }
        return nil
    }

    /// 测试发送注册数据
    func testRegister(username: String, password: String) async -> String? {
        guard let url = URL(string: "http://39.106.24.44:8080/api/test-register") else {
            print("Register: 无效的 URL")
            return nil
        }
        
        print("正在请求: \(url.absoluteString)") // 👈 打印请求链接
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["username": username, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "无响应体"
                print("注册返回非 201 状态码，响应: \(errorBody)")
                return "注册失败: \(errorBody)"
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = json["msg"] as? String {
                return "\(msg)"
            }
        } catch {
            print("网络错误: \(error)")
        }
        return nil
    }
    // MARK: - 登出
    func logout() {
        isAuthenticated = false
    }
}
