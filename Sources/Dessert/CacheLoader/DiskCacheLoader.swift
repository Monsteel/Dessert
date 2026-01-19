
import Foundation

extension DiskCacheLoader {
  /// 기본 디스크 캐시 로더
  /// Note: 기본 디스크 캐시 로더입니다.
  public static let `default` = DiskCacheLoader()
}

/// 디스크 캐시 로더
/// Note: 디스크 캐시를 저장하고 가져오는 기능을 제공합니다.
public struct DiskCacheLoader: CacheLoader, @unchecked Sendable {

  /// 최대 비용 (unit: byte)
  private let totalCostLimit: Int

  /// 파일 매니저
  private let fm: FileManager

  /// 경로
  private let path: String

  /// initializer
  /// - Parameters:
  ///   - fm: 파일 매니저
  ///   - queue: 디스패치 큐
  ///   - path: 경로 (Dessert 하위 경로로 지정 됩니다.)
  public init(
    totalCostLimit: Int = .zero,
    fm: FileManager = .default,
    path: String = ""
  ) {
    self.totalCostLimit = totalCostLimit
    self.fm = fm
    self.path = path
  }

  /// 캐시를 저장합니다.
  /// - Parameters:
  ///   - key: 키
  ///   - value: 캐시 컨테이너
  internal func save(for key: String, _ value: CacheContainer) async throws {
    // Convert key to URL
    guard let remoteURL = URL(string: key) else {
      throw CacheLoaderErrorFactory.invalidURL(key)
    }

    // If the directory does not exits, create it
    if self.fm.fileExists(atPath: self.diskCachePath.path) == false {
      try self.fm.createDirectory(
        at: self.diskCachePath,
        withIntermediateDirectories: true,
        attributes: nil
      )
    }

    // Get local disk cache path
    let localCachePath = self.diskCacheLocalURL(remoteURL).path

    // If the file exists, remove it
    if self.fm.fileExists(atPath: localCachePath) {
      try self.fm.removeItem(atPath: localCachePath)
    }

    // Convert value to data
    let data: Data
    do {
      data = try JSONEncoder().encode(value)
    } catch {
      throw CacheLoaderErrorFactory.failedToEncode(error)
    }

    // Save data to local cache path
    let result = self.fm.createFile(atPath: localCachePath, contents: data, attributes: nil)

    // Resume the continuation
    guard result else { throw CacheLoaderErrorFactory.failedToSaveDiskCache(result) }

    Task.detached {
      try self.clearIfNeeded()
    }
  }

  /// 캐시를 가져옵니다.
  /// - Parameters:
  ///   - key: 키
  /// - Returns: 캐시 컨테이너
  internal func get(for key: String) async throws -> CacheContainer {
    // Convert key to URL
    guard let remoteURL = URL(string: key) else {
      throw CacheLoaderErrorFactory.invalidURL(key)
    }

    // Get local disk cache path
    let localCachePath = self.diskCacheLocalURL(remoteURL).path

    // Get data from local disk cache path
    guard let data = self.fm.contents(atPath: localCachePath) else {
      throw CacheLoaderErrorFactory.diskCacheNotFound(localCachePath)
    }

    do {
      // Convert data to CacheContainer
      let value = try JSONDecoder().decode(CacheContainer.self, from: data)
      return value
    } catch {
      throw CacheLoaderErrorFactory.failedToDecode(error)
    }
  }

  /// 디스크 캐시 경로
  private var diskCachePath: URL {
    let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(
      .cachesDirectory,
      .userDomainMask,
      true
    )[0] as NSString

    let diskCachePath = documentDirectoryPath.appendingPathComponent("Dessert/\(path)")

    return URL(fileURLWithPath: diskCachePath)
  }

  /// 디스크 캐시 로컬 URL
  /// - Parameters:
  ///   - remoteURL: 원격 URL
  /// - Returns: 디스크 캐시 로컬 URL
  private func diskCacheLocalURL(_ remoteURL: URL) -> URL {
    // URL encode the entire remote URL string
    let encodedFilename = remoteURL.absoluteString
      .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? remoteURL.lastPathComponent
    
    return diskCachePath
      .appendingPathComponent(encodedFilename)
      .appendingPathExtension("json")
  }

  /// 디스크 캐시를 삭제합니다.
  internal func clear() async throws {
    do {
      return try self.fm.removeItem(at: self.diskCachePath)
    } catch {
      throw CacheLoaderErrorFactory.failedToClearDiskCache(error)
    }
  }
  
  /// 디스크 캐시 제거가 필요한 경우 제거합니다.
  internal func clearIfNeeded() throws {
    if self.totalCostLimit <= .zero { return }
    
    let keys: Set<URLResourceKey> = [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey]
    
    let urls = try self.fm.contentsOfDirectory(
      at: self.diskCachePath,
      includingPropertiesForKeys: Array(keys),
      options: [.skipsHiddenFiles]
    )
    
    var entries: [Entry] = []
    entries.reserveCapacity(urls.count)
    
    var total: UInt64 = .zero
    
    for url in urls {
      let resourceValues = try url.resourceValues(forKeys: keys)
      guard resourceValues.isRegularFile == true else { continue }
      
      let size = UInt64(resourceValues.fileSize ?? .zero)
      let date = resourceValues.contentModificationDate ?? .distantPast
      
      total += size
      
      entries.append(
        .init(
          url: url,
          size: size,
          date: date
        )
      )
    }
    
    guard total > self.totalCostLimit else { return }
    
    entries.sort { $0.date < $1.date }
    
    var current = total
    
    for e in entries {
      if current <= self.totalCostLimit { break }
      try self.fm.removeItem(at: e.url)
      current = current > e.size ? (current - e.size) : .zero
    }
  }
  
  internal struct Entry {
    let url: URL
    let size: UInt64
    let date: Date
  }
}
