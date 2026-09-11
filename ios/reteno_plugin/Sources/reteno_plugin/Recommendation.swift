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
        let category: [String]?
        let categoryAncestor: [String]?
        let categoryLayout: [String]?
        let categoryParent: [String]?
        let dateCreatedAs: String?
        let dateCreatedEs: String?
        let dateModifiedAs: String?
        let itemGroup: String?
        let nameKeyword: String?
        let productIdAlt: String? // Alternative product_id field
        let tagsAllCategoryNames: String?
        let tagsBestseller: String?
        let tagsCashback: String?
        let tagsCategoryBestseller: String?
        let tagsCredit: String?
        let tagsDelivery: String?
        let tagsDescriptionPriceRange: String?
        let tagsDiscount: String?
        let tagsHasPurchases21Days: String?
        let tagsIsBestseller: String?
        let tagsIsBestsellerByCategories: String?
        let tagsItemGroupId: String?
        let tagsNumPurchases21Days: String?
        let tagsOldPrice: String?
        let tagsOldprice: String?
        let tagsPriceRange: String?
        let tagsRating: String?
        let tagsSale: String?
        let url: URL?
        
        enum CodingKeys: String, CodingKey {
            case productId, name
            case description = "descr"
            case imageUrl, price, category, categoryAncestor, categoryLayout, categoryParent
            case dateCreatedAs = "date_created_as"
            case dateCreatedEs = "date_created_es"
            case dateModifiedAs = "date_modified_as"
            case itemGroup = "item_group"
            case nameKeyword = "name_keyword"
            case productIdAlt = "product_id"
            case tagsAllCategoryNames = "tags_all_category_names"
            case tagsBestseller = "tags_bestseller"
            case tagsCashback = "tags_cashback"
            case tagsCategoryBestseller = "tags_category_bestseller"
            case tagsCredit = "tags_credit"
            case tagsDelivery = "tags_delivery"
            case tagsDescriptionPriceRange = "tags_description_price_range"
            case tagsDiscount = "tags_discount"
            case tagsHasPurchases21Days = "tags_has_purchases_21_days"
            case tagsIsBestseller = "tags_is_bestseller"
            case tagsIsBestsellerByCategories = "tags_is_bestseller_by_categories"
            case tagsItemGroupId = "tags_item_group_id"
            case tagsNumPurchases21Days = "tags_num_purchases_21_days"
            case tagsOldPrice = "tags_old_price"
            case tagsOldprice = "tags_oldprice"
            case tagsPriceRange = "tags_price_range"
            case tagsRating = "tags_rating"
            case tagsSale = "tags_sale"
            case url
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
