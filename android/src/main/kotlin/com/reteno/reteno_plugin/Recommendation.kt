package com.reteno.reteno_plugin

import com.google.gson.annotations.SerializedName
import com.reteno.core.data.remote.model.recommendation.get.RecomBase
import com.reteno.core.domain.model.recommendation.get.RecomFilter
import com.reteno.core.domain.model.recommendation.post.RecomEvent
import com.reteno.core.domain.model.recommendation.post.RecomEventType
import java.time.ZonedDateTime

data class RecommendationResponse(
    @SerializedName("productId")
    override val productId: String,
    @SerializedName("name")
    val name: String?,
    @SerializedName("descr")
    val descr: String?,
    @SerializedName("imageUrl")
    val imageUrl: String?,
    @SerializedName("price")
    val price: Float?,
    @SerializedName("category")
    val category: List<String>?,
    @SerializedName("categoryAncestor")
    val categoryAncestor: List<String>?,
    @SerializedName("categoryLayout")
    val categoryLayout: List<String>?,
    @SerializedName("categoryParent")
    val categoryParent: List<String>?,
    @SerializedName("date_created_as")
    val dateCreatedAs: String?,
    @SerializedName("date_created_es")
    val dateCreatedEs: String?,
    @SerializedName("date_modified_as")
    val dateModifiedAs: String?,
    @SerializedName("item_group")
    val itemGroup: String?,
    @SerializedName("name_keyword")
    val nameKeyword: String?,
    @SerializedName("product_id")
    val productIdAlt: String?, // Alternative product_id field
    @SerializedName("tags_all_category_names")
    val tagsAllCategoryNames: String?,
    @SerializedName("tags_bestseller")
    val tagsBestseller: String?,
    @SerializedName("tags_cashback")
    val tagsCashback: String?,
    @SerializedName("tags_category_bestseller")
    val tagsCategoryBestseller: String?,
    @SerializedName("tags_credit")
    val tagsCredit: String?,
    @SerializedName("tags_delivery")
    val tagsDelivery: String?,
    @SerializedName("tags_description_price_range")
    val tagsDescriptionPriceRange: String?,
    @SerializedName("tags_discount")
    val tagsDiscount: String?,
    @SerializedName("tags_has_purchases_21_days")
    val tagsHasPurchases21Days: String?,
    @SerializedName("tags_is_bestseller")
    val tagsIsBestseller: String?,
    @SerializedName("tags_is_bestseller_by_categories")
    val tagsIsBestsellerByCategories: String?,
    @SerializedName("tags_item_group_id")
    val tagsItemGroupId: String?,
    @SerializedName("tags_num_purchases_21_days")
    val tagsNumPurchases21Days: String?,
    @SerializedName("tags_old_price")
    val tagsOldPrice: String?,
    @SerializedName("tags_oldprice")
    val tagsOldprice: String?,
    @SerializedName("tags_price_range")
    val tagsPriceRange: String?,
    @SerializedName("tags_rating")
    val tagsRating: String?,
    @SerializedName("tags_sale")
    val tagsSale: String?,
    @SerializedName("url")
    val url: String?
) : RecomBase

fun RecommendationResponse.toNativeRecommendation(): NativeRecommendation {
    // Convert price from Float to Double
    val convertedPrice = price?.toDouble()

    return NativeRecommendation(
        productId = productId,
        name = name,
        description = descr,
        imageUrl = imageUrl,
        price = convertedPrice,
        category = category,
        categoryAncestor = categoryAncestor,
        categoryLayout = categoryLayout,
        categoryParent = categoryParent,
        dateCreatedAs = dateCreatedAs,
        dateCreatedEs = dateCreatedEs,
        dateModifiedAs = dateModifiedAs,
        itemGroup = itemGroup,
        nameKeyword = nameKeyword,
        productIdAlt = productIdAlt,
        tagsAllCategoryNames = tagsAllCategoryNames,
        tagsBestseller = tagsBestseller,
        tagsCashback = tagsCashback,
        tagsCategoryBestseller = tagsCategoryBestseller,
        tagsCredit = tagsCredit,
        tagsDelivery = tagsDelivery,
        tagsDescriptionPriceRange = tagsDescriptionPriceRange,
        tagsDiscount = tagsDiscount,
        tagsHasPurchases21Days = tagsHasPurchases21Days,
        tagsIsBestseller = tagsIsBestseller,
        tagsIsBestsellerByCategories = tagsIsBestsellerByCategories,
        tagsItemGroupId = tagsItemGroupId,
        tagsNumPurchases21Days = tagsNumPurchases21Days,
        tagsOldPrice = tagsOldPrice,
        tagsOldprice = tagsOldprice,
        tagsPriceRange = tagsPriceRange,
        tagsRating = tagsRating,
        tagsSale = tagsSale,
        url = url
    )
}
fun convertToRecomFilter(nativeFilters: List<NativeRecomFilter>?): RecomFilter? {
    return nativeFilters?.firstOrNull()?.let { nativeFilter ->
        val filteredValues = nativeFilter.values.filterNotNull()
        RecomFilter(nativeFilter.name, filteredValues)
    }
}

fun convertToRecomFilterList(nativeFilters: List<NativeRecomFilter>?): List<RecomFilter>? {
    return nativeFilters?.map { nativeFilter ->
        val filteredValues = nativeFilter.values.filterNotNull()
        RecomFilter(nativeFilter.name, filteredValues)
    }
}

fun convertToRecomEventList(nativeEvents: NativeRecomEvents): List<RecomEvent> {
    val recomEvents = mutableListOf<RecomEvent>()
    nativeEvents.events.forEach { nativeEvent ->
        if (nativeEvent != null) {
            val recomEventType = convertNativeEventType(nativeEvent.eventType)
            val occurred = ZonedDateTime.parse(nativeEvent.dateOccurred)
            recomEvents.add(RecomEvent(recomEventType, occurred, nativeEvent.productId))
        }
    }
    return recomEvents
}

// Helper function to convert NativeRecomEventType to RecomEventType
private fun convertNativeEventType(nativeType: NativeRecomEventType): RecomEventType {
     return when (nativeType) {
       NativeRecomEventType.CLICK -> return RecomEventType.CLICKS
       NativeRecomEventType.IMPRESSION -> return RecomEventType.IMPRESSIONS
       // Add other cases as needed
       else -> throw IllegalArgumentException("Unknown NativeRecomEventType: $nativeType")
     }
}