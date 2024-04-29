//
//  Recommendation.swift
//  reteno_plugin
//
//  Created by Denys on 24.04.2024.
//

import Foundation
import Reteno

struct Recommendation: Decodable, RecommendableProduct {
    
    let productId: String
    let name: String?
    let description: String?
    let imageUrl: URL?
    let price: Float?
    
    enum CodingKeys: String, CodingKey {
        case productId, name, description = "descr", imageUrl, price
    }
    
}

struct RecomEventContainer {
    public var recomVariantId: String
    public var impressions: [RecomEvent]
    public var clicks: [RecomEvent]
    
    public init(recomVariantId: String, impressions: [RecomEvent] = [], clicks: [RecomEvent] = []) {
        self.recomVariantId = recomVariantId
        self.impressions = impressions
        self.clicks = clicks
    }
}
