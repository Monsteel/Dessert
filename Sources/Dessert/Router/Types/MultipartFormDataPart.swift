
import Foundation

/// MultipartFormDataPart
///
/// multipart로 전달될 part 입니다.
public struct MultipartFormDataPart: Hashable {
  /// Data
  /// 
  /// multipart로 전달될 data 입니다.
  public let data: Data
  
  /// Name
  /// 
  /// multipart의 name 입니다.
  public let name: String

  /// FileName
  ///
  /// multipart의 fileName 입니다.
  /// 파일이 아닐 경우 nil로 설정합니다.
  public let fileName: String?

  /// MimeType
  ///
  /// multipart의 mimeType 입니다.
  public let mimeType: String

  /// Initialize
  ///
  /// - Parameters:
  ///   - data: multipart로 전달될 data 입니다.
  ///   - name: multipart의 name 입니다.
  ///   - fileName: multipart의 fileName 입니다. 파일이 아닐 경우 nil로 설정합니다.
  ///   - mimeType: multipart의 mimeType 입니다.
  public init(
    data: Data,
    name: String,
    fileName: String? = nil,
    mimeType: String
  ) {
    self.data = data
    self.name = name
    self.fileName = fileName
    self.mimeType = mimeType
  }
}
