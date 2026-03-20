import SwiftUI

struct InfoView: View {
    @StateObject var viewModel: InfoViewModel

    var body: some View {
        ZStack {
            artwork
            VStack {
                trackInfo
                Spacer()
                trackTime
                Spacer()
                trackPosition
            }
            .padding(6)
        }
    }

    private var artwork: some View {
        GeometryReader { geometry in
            Image(uiImage: viewModel.artwork)
                .resizable()
            //图片填满区域
                .scaledToFill()
            //设置半透明度
                .opacity(0.2)
            //强制高度等于父容器高度
                .frame(height: geometry.size.height)
        }
    }

    private var trackInfo: some View {
        //左对齐
        VStack(alignment: .leading) {
            Text(viewModel.artist)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.infoViewText)
            Text(viewModel.title)
                .font(.system(size: 17))
                .foregroundColor(.infoViewText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    //当前时间
    private var trackTime: some View {
        Text(viewModel.time)
            .font(.custom("Menlo-Regular", size: 48))
            .foregroundColor(.infoViewText)
    }

    //播放进度设置
    private var trackPosition: some View {
        VStack {
            Text(viewModel.position)
                .font(.system(size: 14))
                .foregroundColor(.infoViewText)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

#Preview {
    VStack {
        Spacer()
            .frame(height: 50)
        InfoView(viewModel: InfoViewModel(musicPlayer: MusicPlayer()))
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(.white)
        Spacer()
    }
    .background(.black)
}
