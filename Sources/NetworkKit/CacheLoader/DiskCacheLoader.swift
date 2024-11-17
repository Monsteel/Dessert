
import Foundation

extension DiskCacheLoader {
  internal static let shared = DiskCacheLoader()
}

internal final class DiskCacheLoader: CacheLoader {
  private let fm: FileManager
  private let queue: DispatchQueue

  internal init(
    fm: FileManager = .default,
    queue: DispatchQueue = DispatchQueue(label: "com.NetworkKit.DiskCacheLoader")
  ) {
    self.fm = fm
    self.queue = queue
  }

  internal func save(for key: String, _ value: CacheContainer) async throws {
    return try await withCheckedThrowingContinuation { continuation in
      queue.async {
        do {
          // Convert key to URL
          guard let remoteURL = URL(string: key) else {
            return continuation.resume(throwing: CacheLoaderErrorFactory.invalidURL(key))
          }
          
          // If the directory does not exits, create it
          if self.fm.fileExists(atPath: self.diskCachePath.path) == false {
            try self.fm.createDirectory(at: self.diskCachePath, withIntermediateDirectories: true, attributes: nil)
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
            return continuation.resume(throwing: CacheLoaderErrorFactory.failedToEncode(error))
          }
          
          // Save data to local cache path
          let result = self.fm.createFile(atPath: localCachePath, contents: data, attributes: nil)
          
          // Resume the continuation
          if result {
            return continuation.resume(returning: Void())
          } else {
            return continuation.resume(throwing: CacheLoaderErrorFactory.failedToSaveDiskCache(result))
          }
        } catch {
          return continuation.resume(throwing: CacheLoaderErrorFactory.unknown(error))
        }
      }
    }
  }

  internal func get(for key: String) async throws -> CacheContainer {
    return try await withCheckedThrowingContinuation { continuation in
      queue.async {
        // Convert key to URL
        guard let remoteURL = URL(string: key) else {
          return continuation.resume(throwing: CacheLoaderErrorFactory.invalidURL(key))
        }

        // Get local disk cache path
        let localCachePath = self.diskCacheLocalURL(remoteURL).path

        // Get data from local disk cache path
        guard let data = self.fm.contents(atPath: localCachePath) else {
          return continuation.resume(throwing: CacheLoaderErrorFactory.diskCacheNotFound(localCachePath))
        }

        do {
          // Convert data to CacheContainer
          let value = try JSONDecoder().decode(CacheContainer.self, from: data)
          return continuation.resume(returning: value)
        } catch {
          return continuation.resume(throwing: CacheLoaderErrorFactory.failedToDecode(error))
        }
      }
    }
  }

  private var diskCachePath: URL {
    let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(
      .cachesDirectory,
      .userDomainMask,
      true
    )[0] as NSString

    let diskCachePath = documentDirectoryPath.appendingPathComponent("NetworkKit")

    return URL(fileURLWithPath: diskCachePath)
  }

  private func diskCacheLocalURL(_ remoteURL: URL) -> URL {
    // Get URL components to include query parameters in the cache file name
    guard let components = URLComponents(url: remoteURL, resolvingAgainstBaseURL: false) else {
      return diskCachePath
        .appendingPathComponent(remoteURL.lastPathComponent)
        .appendingPathExtension("json")
    }
    
    // Create a unique filename using the path and query parameters
    var filename = remoteURL.lastPathComponent
    if let queryItems = components.queryItems {
      let queryString = queryItems
        .sorted { $0.name < $1.name }
        .map { item in
          if let value = item.value {
            return "\(item.name)=\(value)"
          }
          return item.name
        }
        .joined(separator: "&")
      
      if !queryString.isEmpty {
        filename += "_\(queryString)"
      }
    }
    
    return diskCachePath
      .appendingPathComponent(filename)
      .appendingPathExtension("json")
  }
  
  internal func clear() async throws {
    return try await withCheckedThrowingContinuation { continuation in
      queue.async {
        do {
          try self.fm.removeItem(at: self.diskCachePath)
          return continuation.resume(returning: Void())
        } catch {
          return continuation.resume(throwing: CacheLoaderErrorFactory.failedToClearDiskCache(error))
        }
      }
    }
  }
}
