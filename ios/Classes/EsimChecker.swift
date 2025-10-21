import Foundation
import CoreTelephony

@available(iOS 12.0, *)
class EsimChecker: NSObject {

    public var handler: EventCallbackHandler?

    func isSupportESim() -> Bool {
        let provisioning = CTCellularPlanProvisioning()
        return provisioning.supportsCellularPlan()
    }

    func installEsimProfile(
        address: String,
        matchingID: String?,
        oid: String?,
        confirmationCode: String?,
        iccid: String?,
        eid: String?
    ) {
        let request = CTCellularPlanProvisioningRequest()
        request.address = address
        if let matchingID = matchingID { request.matchingID = matchingID }
        if let oid = oid { request.oid = oid }
        if let confirmationCode = confirmationCode { request.confirmationCode = confirmationCode }
        if let iccid = iccid { request.iccid = iccid }
        if let eid = eid { request.eid = eid }

        let provisioning = CTCellularPlanProvisioning()

        guard provisioning.supportsCellularPlan() else {
            handler?.send("unsupport", [:])
            return
        }

        provisioning.addPlan(with: request) { result in
            switch result {
            case .unknown:
                self.handler?.send("unknown", [:])
            case .fail:
                self.handler?.send("fail", [:])
            case .success:
                self.handler?.send("success", [:])
            case .cancel:
                self.handler?.send("cancel", [:])
            @unknown default:
                self.handler?.send("unknown", [:])
            }
        }
    }
}
