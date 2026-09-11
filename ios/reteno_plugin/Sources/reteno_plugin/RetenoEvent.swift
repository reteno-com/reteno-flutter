//
//  RetenoEvent.swift
//  reteno_plugin
//
//  Created by Roman Nakonechnyi on 30.03.2023.
//

import Foundation
import Reteno

struct RetenoCustomEventParameter: Codable {
    init(dictionary: [String: Any]?) throws {
        self = try JSONDecoder().decode(RetenoCustomEventParameter.self, from: JSONSerialization.data(withJSONObject: dictionary ?? [:]))
    }
    let name: String;
    let value: String?;
}

struct RetenoCustomEvent: Codable {
    init(dictionary: [String: Any]?) throws {
        self = try JSONDecoder().decode(RetenoCustomEvent.self, from: JSONSerialization.data(withJSONObject: dictionary ?? [:]))
    }
    let eventName: String;
    let date: String;
    let parameters: [RetenoCustomEventParameter];
    let forcePush: Bool?;
    
    enum CodingKeys: String, CodingKey{
        case eventName = "event_type_key"
        case date = "date_occurred"
        case parameters
        case forcePush = "force_push"
    }
}

public struct RetenoEventPayload: Codable {
    init(eventName: String, stringDate: String, parameters: [NativeCustomEventParameter], forcePush: Bool?) {
        self.eventName = eventName;

        let dateFormatter = ISO8601DateFormatter();
        self.date = dateFormatter.date(from: stringDate) ?? Date();

        self.forcePush = forcePush == nil ? false : forcePush!;
        
        var paramArr = [Event.Parameter]();
        for param in parameters {
            paramArr.append(Event.Parameter(name: param.name, value: param.value ?? ""));
        }
        self.parameters = paramArr;
    }

    let eventName: String;
    let date: Date;
    let parameters: [Event.Parameter];
    let forcePush: Bool;
}

//public struct RetenoEvent {
//    private init() {}
//    
//    private static func getStringOrNil(input: String?) -> String? {
//        return (input ?? "").isEmpty ? nil : input!
//    }
//    
//    public static func buildEventPayload(payload: NSDictionary) throws -> RetenoEventPayload {
//        let data = payload as? [String: Any];
//        do {
//            let payloadStruct = try RetenoCustomEvent(dictionary: data);
//            let requestPayload = RetenoEventPayload(
//                eventName: payloadStruct.eventName,
//                stringDate: payloadStruct.date,
//                parameters: payloadStruct.parameters,
//                forcePush: payloadStruct.forcePush
//            );
//            
//            return requestPayload;
//        } catch {
//            throw error;
//        }
//    }
//}
