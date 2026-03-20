// LoginView.swift
import SwiftUI
import SwiftData

struct LoginView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isRegisterMode = false
    
    @EnvironmentObject var viewModel: LoginViewModel
    @Environment(\.modelContext) var context

    @State private var testResult = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text(isRegisterMode ? "注册新账号" : "用户登录")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 40)
                    
                    // 账号输入
                    TextField("账号（必填）", text: $username)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    // 邮箱输入（仅注册时显示）
                    if isRegisterMode {
                        TextField("邮箱（可选）", text: $email)
                            .keyboardType(.emailAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }
                    
                    // 密码输入
                    SecureField("密码（必填）", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    // 错误提示
                    if let errorMsg = viewModel.errorMessage {
                        Text(errorMsg)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    // 登录/注册按钮
                    Button(action: handleAction) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(width: 20, height: 20)
                            } else {
                                Text(isRegisterMode ? "注册" : "登录")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .frame(width: 220)
                    .disabled(username.isEmpty || password.isEmpty || viewModel.isLoading)
                    
                    // 切换模式
                    Button(action: toggleMode) {
                        Text(isRegisterMode ? "已有账号？去登录" : "没有账号？去注册")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .padding(.top, 8)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                viewModel.errorMessage = nil
                password = "" // 安全起见
            }
            Button("测试服务器连接") {
                Task {
                    testResult = await viewModel.testPing() ?? "连接失败"
                }
            }

            Button("测试发送注册") {
                Task {
                    testResult = await viewModel.testRegister(username: "testuser", password: "123456") ?? "发送失败"
                }
            }

            Text(testResult)
                .font(.caption)
                .foregroundColor(testResult.contains("✅") ? .green : .red)
                .padding()
        }
    }
    
    private func handleAction() {
        viewModel.errorMessage = nil
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isRegisterMode {
            viewModel.register(
                username: cleanUsername,
                email: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email,
                password: password,
                modelContext: context
            )
            // 注册成功后自动切回登录（可选）
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if viewModel.isAuthenticated == false {
                    isRegisterMode = false
                    password = ""
                }
            }
        } else {
            Task {
                let success = await viewModel.login(
                    username: cleanUsername,
                    password: password,
                    modelContext: context
                )
                if success {
                    // 这里通常会跳转到主界面（由 App 层控制）
                }
            }
        }
    }
    
    private func toggleMode() {
        isRegisterMode.toggle()
        viewModel.errorMessage = nil
        password = ""
        email = ""
    }
}

#Preview {
    let container = try! ModelContainer(for: Schema([User.self]))
    return LoginView()
        .modelContainer(container)
        .environmentObject(LoginViewModel())
}
