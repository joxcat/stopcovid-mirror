// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(OSX)
  import AppKit.NSImage
  internal typealias AssetColorTypeAlias = NSColor
  internal typealias AssetImageTypeAlias = NSImage
#elseif os(iOS) || os(tvOS) || os(watchOS)
  import UIKit.UIImage
  internal typealias AssetColorTypeAlias = UIColor
  internal typealias AssetImageTypeAlias = UIImage
#endif

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal enum Colors {
    internal static let background = ColorAsset(name: "background")
    internal static let barBackground = ColorAsset(name: "barBackground")
    internal static let buttonBackground = ColorAsset(name: "buttonBackground")
    internal static let buttonLabel = ColorAsset(name: "buttonLabel")
    internal static let error = ColorAsset(name: "error")
    internal static let info = ColorAsset(name: "info")
    internal static let notificationCellBackground = ColorAsset(name: "notificationCellBackground")
    internal static let secondaryButtonBackground = ColorAsset(name: "secondaryButtonBackground")
    internal static let secondaryButtonLabel = ColorAsset(name: "secondaryButtonLabel")
    internal static let textHighlight = ColorAsset(name: "textHighlight")
    internal static let tint = ColorAsset(name: "tint")
  }
  internal enum Images {
    internal static let airCheck = ImageAsset(name: "AirCheck")
    internal static let cough = ImageAsset(name: "Cough")
    internal static let distance = ImageAsset(name: "Distance")
    internal static let hands = ImageAsset(name: "Hands")
    internal static let mask = ImageAsset(name: "Mask")
    internal static let tissues = ImageAsset(name: "Tissues")
    internal static let visage = ImageAsset(name: "Visage")
    internal static let audio = ImageAsset(name: "Audio")
    internal static let manageData = ImageAsset(name: "ManageData")
    internal static let privacy = ImageAsset(name: "Privacy")
    internal static let qrCodePlaceholder = ImageAsset(name: "QRCodePlaceholder")
    internal static let replay = ImageAsset(name: "Replay")
    internal static let visual = ImageAsset(name: "Visual")
    internal static let chevron = ImageAsset(name: "chevron")
    internal static let gradient = ImageAsset(name: "gradient")
    internal static let more = ImageAsset(name: "more")
    internal static let pause = ImageAsset(name: "pause")
    internal static let phone = ImageAsset(name: "phone")
    internal static let play = ImageAsset(name: "play")
    internal static let bluetooth = ImageAsset(name: "Bluetooth")
    internal static let logo = ImageAsset(name: "Logo")
    internal static let notification = ImageAsset(name: "Notification")
    internal static let support = ImageAsset(name: "Support")
    internal static let republicFrLogo = ImageAsset(name: "RepublicFrLogo")
    internal static let santePubliqueLogo = ImageAsset(name: "SantePubliqueLogo")
    internal static let diagnosis = ImageAsset(name: "Diagnosis")
    internal static let envoiData = ImageAsset(name: "EnvoiData")
    internal static let maintenance = ImageAsset(name: "Maintenance")
    internal static let proximity = ImageAsset(name: "Proximity")
    internal static let proximityOff = ImageAsset(name: "ProximityOff")
    internal static let share = ImageAsset(name: "Share")
    internal static let sick = ImageAsset(name: "Sick")
    internal static let tabBarProximityNormal = ImageAsset(name: "TabBarProximity-Normal")
    internal static let tabBarSharingNormal = ImageAsset(name: "TabBarSharing-Normal")
    internal static let tabBarSickNormal = ImageAsset(name: "TabBarSick-Normal")
    internal static let tabBarSupportNormal = ImageAsset(name: "TabBarSupport-Normal")
    internal static let tabBarProximitySelected = ImageAsset(name: "TabBarProximity-Selected")
    internal static let tabBarSharingSelected = ImageAsset(name: "TabBarSharing-Selected")
    internal static let tabBarSickSelected = ImageAsset(name: "TabBarSick-Selected")
    internal static let tabBarSupportSelected = ImageAsset(name: "TabBarSupport-Selected")
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal struct ColorAsset {
  internal fileprivate(set) var name: String

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, OSX 10.13, *)
  internal var color: AssetColorTypeAlias {
    return AssetColorTypeAlias(asset: self)
  }
}

internal extension AssetColorTypeAlias {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, OSX 10.13, *)
  convenience init!(asset: ColorAsset) {
    let bundle = Bundle(for: BundleToken.self)
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(OSX)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

internal struct DataAsset {
  internal fileprivate(set) var name: String

  #if os(iOS) || os(tvOS) || os(OSX)
  @available(iOS 9.0, tvOS 9.0, OSX 10.11, *)
  internal var data: NSDataAsset {
    return NSDataAsset(asset: self)
  }
  #endif
}

#if os(iOS) || os(tvOS) || os(OSX)
@available(iOS 9.0, tvOS 9.0, OSX 10.11, *)
internal extension NSDataAsset {
  convenience init!(asset: DataAsset) {
    let bundle = Bundle(for: BundleToken.self)
    #if os(iOS) || os(tvOS)
    self.init(name: asset.name, bundle: bundle)
    #elseif os(OSX)
    self.init(name: NSDataAsset.Name(asset.name), bundle: bundle)
    #endif
  }
}
#endif

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  internal var image: AssetImageTypeAlias {
    let bundle = Bundle(for: BundleToken.self)
    #if os(iOS) || os(tvOS)
    let image = AssetImageTypeAlias(named: name, in: bundle, compatibleWith: nil)
    #elseif os(OSX)
    let image = bundle.image(forResource: NSImage.Name(name))
    #elseif os(watchOS)
    let image = AssetImageTypeAlias(named: name)
    #endif
    guard let result = image else { fatalError("Unable to load image named \(name).") }
    return result
  }
}

internal extension AssetImageTypeAlias {
  @available(iOS 1.0, tvOS 1.0, watchOS 1.0, *)
  @available(OSX, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init!(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = Bundle(for: BundleToken.self)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(OSX)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

private final class BundleToken {}
