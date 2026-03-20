import Foundation
import MediaPlayer

/// @mockable
protocol MusicLibraryable: Sendable {
    //创建歌曲列表，返回歌曲类型数组
    func makePlaylist(isShuffled: Bool) -> [MPMediaItem]
    //根据唯一id查找歌曲
    func findTracks(with ids: [MPMediaEntityPersistentID]) -> [MPMediaItem]
    //验证歌曲是否有效
    func areTrackIDsValid(_ ids: [MPMediaEntityPersistentID]) -> Bool
}

final class MusicLibrary: MusicLibraryable {
    private var libraryQuery: MPMediaQuery {
        //获取设备上所有可用的歌曲
        MPMediaQuery.songs()
    }

    func makePlaylist(isShuffled: Bool) -> [MPMediaItem] {
        //初始化队列，执行打乱播放
        guard let tracks = libraryQuery.items else {
            return []
        }
        return isShuffled ? tracks.shuffled() : tracks
    }

    func findTracks(with ids: [MPMediaEntityPersistentID]) -> [MPMediaItem] {
        //查找唯一的歌曲对象
        let query = libraryQuery
        //通过id查歌曲对象
        return ids.compactMap { (id: MPMediaEntityPersistentID) -> MPMediaItem? in
            let predicate = MPMediaPropertyPredicate(value: id, forProperty: MPMediaItemPropertyPersistentID)
            query.addFilterPredicate(predicate)
            let items = query.items
            query.removeFilterPredicate(predicate)
            return items?.first // expecting unique id per media item, so take first
        }
    }
    
    func areTrackIDsValid(_ ids: [MPMediaEntityPersistentID]) -> Bool {
        //获取所有的歌曲对象
        let items = libraryQuery.items ?? []

        // if the count is different, then a track got deleted from / added to the libary
        guard items.count == ids.count else {
            return false
        }

        // if the count is the same, check all the tracks are still in the library
        let refreshedItems = findTracks(with: ids)
        guard refreshedItems.count == ids.count else {
            return false
        }

        return true
    }
}
