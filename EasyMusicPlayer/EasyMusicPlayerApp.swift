import SwiftUI
import SwiftData
@main
//遵循App协议的结构体必须提供一个body: some scene
struct EasyMusicPlayerApp: App {
    //初始化服务依赖
    private let userService = UserService()

    var sharedModelContainer: ModelContainer
    
    @StateObject private var loginVM = LoginViewModel()
    
    
    init() {
        #if DEBUG
        if __isSnapshot {
            userService.isDistortionEnabled = true
            userService.isLofiEnabled = true
            userService.currentTrackID = nil
            userService.trackIDs = nil
            userService.repeatMode = .all
        }
        #endif
        
        do {
            let schema = Schema([User.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            sharedModelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer: $error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            // 示例：根据登录状态切换视图
            Group {
                if loginVM.isAuthenticated {
                    PlayerView()
                } else {
                    LoginView()
                }
            }
            .modelContainer(sharedModelContainer)
            .environmentObject(loginVM)
        }
    }
}
