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
    val price: Float?
) : RecomBase

fun RecommendationResponse.toNativeRecommendation(): NativeRecommendation {
    // Convert price from Float to Double
    val convertedPrice = price?.toDouble()

    return NativeRecommendation(
        productId = productId,
        name = name,
        description = descr,
        imageUrl = imageUrl,
        price = convertedPrice
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