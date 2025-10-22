import Foundation
import CoreTelephony

@available(iOS 10.0, *)
class EsimChecker: NSObject {
    
    public var handler: EventCallbackHandler?
    
    private let internalSupportedModels: Set<String> = [
        "iPhone12,1", "iPhone12,3", "iPhone12,5",
        "iPhone13,1", "iPhone13,2", "iPhone13,3", "iPhone13,4",
        "iPhone14,2", "iPhone14,3", "iPhone14,4", "iPhone14,5",
        "iPhone14,7", "iPhone14,8", "iPhone15,2", "iPhone15,3",
        "iPhone15,4", "iPhone15,5", "iPhone16,1", "iPhone16,2",
        "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4", "iPhone17,5",
        "iPhone18,1", "iPhone18,2", "iPhone18,3", "iPhone18,4",
        "iPhone12,8", "iPhone14,6",
        "iPad6,8", "iPad6,12", "iPad7,2", "iPad7,4", "iPad7,6", "iPad7,12",
        "iPad8,3", "iPad8,4", "iPad8,7", "iPad8,8", "iPad8,10", "iPad8,12",
        "iPad11,2", "iPad11,4", "iPad11,7", "iPad12,2", "iPad13,2", "iPad13,6",
        "iPad13,7", "iPad13,10", "iPad13,11", "iPad13,17", "iPad13,19",
        "iPad14,2", "iPad14,4", "iPad14,6", "iPad14,8", "iPad14,9", "iPad14,10", "iPad14,11",
        "iPad15,3", "iPad15,4", "iPad15,5", "iPad15,6", "iPad15,7", "iPad15,8",
        "iPad16,1", "iPad16,2", "iPad16,3", "iPad16,4", "iPad16,5", "iPad16,6"
    ]
    
    private let identifier: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }()
    
    func isSupportESim(customModels: [String] = []) -> Bool {
        let allModels = internalSupportedModels.union(customModels)
        let modelSupported = allModels.contains { identifier.contains($0) }
        
        if #available(iOS 12.0, *) {
            let provisioning = CTCellularPlanProvisioning()
            let systemSupported = provisioning.supportsCellularPlan()
            return modelSupported || systemSupported
        }
        
        return modelSupported
    }
    
    func installEsimProfile(
        address: String,
        matchingID: String? = nil,
        oid: String? = nil,
        confirmationCode: String? = nil,
        iccid: String? = nil,
        eid: String? = nil
    ) {
        guard isSupportESim() else {
            handler?.send("unsupport", [:])
            return
        }
        
        if #available(iOS 12.0, *) {
            let request = CTCellularPlanProvisioningRequest()
            configureRequest(request, with: address, matchingID, oid, confirmationCode, iccid, eid)
            
            let provisioning = CTCellularPlanProvisioning()
            provisioning.addPlan(with: request) { result in
                self.handleInstallationResult(result)
            }
        } else {
            handler?.send("unsupport", [:])
        }
    }
    
    private func configureRequest(
        _ request: CTCellularPlanProvisioningRequest,
        with address: String,
        _ matchingID: String?,
        _ oid: String?,
        _ confirmationCode: String?,
        _ iccid: String?,
        _ eid: String?
    ) {
        request.address = address
        if let matchingID = matchingID { request.matchingID = matchingID }
        if let oid = oid { request.oid = oid }
        if let confirmationCode = confirmationCode { request.confirmationCode = confirmationCode }
        if let iccid = iccid { request.iccid = iccid }
        if let eid = eid { request.eid = eid }
    }
    
    private func handleInstallationResult(_ result: CTCellularPlanProvisioningAddPlanResult) {
        switch result {
        case .unknown:
            handler?.send("unknown", [:])
        case .fail:
            handler?.send("fail", [:])
        case .success:
            handler?.send("success", [:])
        case .cancel:
            handler?.send("cancel", [:])
        @unknown default:
            handler?.send("unknown", [:])
        }
    }
}