import Foundation

//弹窗模型
struct AlertModel {
    //弹窗标题
    let title: String
    //弹窗文本
    let text: String
    //按钮文字
    let buttonTitle: String
    //是否显示弹窗
    var isPresented = true
}

//提供一个空状态的默认值，不显示任何弹窗
//extension：为类、结构体、枚举、协议添加一个内容
extension AlertModel {
    //静态空常量
    static let empty = AlertModel(title: "", text: "", buttonTitle: "", isPresented: false)
}
